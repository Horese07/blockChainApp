import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web3dart/crypto.dart';
import 'dart:typed_data';

class ContractLinking extends ChangeNotifier {
  final String _rpcUrl = "http://127.0.0.1:7545";
  final String _wsUrl = "ws://127.0.0.1:7545/";
  final String _privateKey =
      "c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3";

  late Web3Client _client;
  late String _abiCode;

  late EthereumAddress _contractAddress;
  late Credentials _credentials;

  late DeployedContract _contract;
  late ContractFunction _yourName;
  late ContractFunction _setName;

  String deployedName = "";
  String get contractAddress => _contractAddress.hex;
  bool isLoading = true;
  String? errorMessage;

  ContractLinking() {
    initialSetup();
  }

  Future<void> initialSetup() async {
    try {
      _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
        return IOWebSocketChannel.connect(_wsUrl).cast<String>();
      });

      await _getAbi();
      await _getCredentials();
      await _getDeployedContract();
    } catch (e) {
      errorMessage = "Error during setup: $e";
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _getAbi() async {
    try {
      String abiStringFile =
          await rootBundle.loadString("src/artifacts/HelloWorld.json");
      var jsonAbi = jsonDecode(abiStringFile);
      _abiCode = jsonEncode(jsonAbi["abi"]);
      
      // Get the contract address from the network ID (5777 from Ganache)
      // If 5777 is not found, try others or default
      final networks = jsonAbi["networks"];
      final networkId = "5777"; 
      
      if (networks[networkId] != null) {
         _contractAddress =
          EthereumAddress.fromHex(networks[networkId]["address"]);
      } else {
        // Fallback or iterate keys if needed, but for this setup 5777 is expected
        // Check if any network exists
        if (networks.keys.isNotEmpty) {
           String firstKey = networks.keys.first;
           _contractAddress = EthereumAddress.fromHex(networks[firstKey]["address"]);
        } else {
           throw Exception("Contract not deployed on any network in artifact");
        }
      }

     
      
      print("Contract Address: $_contractAddress");
    } catch (e) {
      print("Error getting ABI: $e");
      rethrow;
    }
  }

  Future<void> _getCredentials() async {
    // Handling private key manually as per README hint for simple setups
    // In production, never hardcode keys using EthPrivateKey.fromHex
    _credentials = EthPrivateKey.fromHex(_privateKey);
  }

  Future<void> _getDeployedContract() async {
    try {
      _contract = DeployedContract(
          ContractAbi.fromJson(_abiCode, "HelloWorld"), _contractAddress);

      _yourName = _contract.function("yourName");
      _setName = _contract.function("setName");

      await getName();
      errorMessage = null;
    } catch (e) {
      errorMessage = "Error getting deployed contract: $e";
      print(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getName() async {
    try {
      // For reading data
      var currentName = await _client
          .call(contract: _contract, function: _yourName, params: []);
      deployedName = currentName[0];
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error getting name: $e");
      errorMessage = "Failed to fetch name";
      notifyListeners();
    }
  }

  Future<void> setName(String nameToSet) async {
    isLoading = true;
    notifyListeners();
    try {
      // For writing data
      await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract,
          function: _setName,
          parameters: [nameToSet],
          maxGas: 1000000 
        ),
        chainId: 1337 // Default Ganache Chain ID (often 1337 even if netId is 5777)
      );
      
      // Wait a bit for block to be mined (optional but helps UI update)
      await Future.delayed(const Duration(seconds: 2));
      await getName();
    } catch (e) {
      print("Error setting name: $e");
      errorMessage = "Failed to set name: $e";
      isLoading = false;
      notifyListeners();
    }
  }
}
