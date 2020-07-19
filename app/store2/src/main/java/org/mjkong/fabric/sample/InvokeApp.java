package org.mjkong.fabric.sample;

import org.hyperledger.fabric.gateway.Contract;
import org.hyperledger.fabric.gateway.Gateway;
import org.hyperledger.fabric.gateway.Network;
import org.hyperledger.fabric.gateway.Wallet;

import java.nio.file.Path;
import java.nio.file.Paths;

public class InvokeApp {

    static {
        System.setProperty("org.hyperledger.fabric.sdk.service_discovery.as_localhost", "true");
    }

    public static void main(String[] args) throws Exception {
        // Load a file system based wallet for managing identities.
        Path walletPath = Paths.get("wallet");
        Wallet wallet = Wallet.createFileSystemWallet(walletPath);

        // load a CCP
        Path networkConfigPath = Paths.get(".", "config", "mymarketStore2Connection.json");

        Gateway.Builder builder = Gateway.createBuilder();
        builder.identity(wallet, "User1@store2.mymarket.com").networkConfig(networkConfigPath).discovery(true);

        // create a gateway connection
        try (Gateway gateway = builder.connect()) {

            // get the network and contract
            Network network = gateway.getNetwork("mymarketchannel");
            Contract contract = network.getContract("marketcc");
            contract.submitTransaction("registCategory", "cat1", "cat1");

            byte[] result;

            result = contract.evaluateTransaction("getCategories");
            System.out.println(new String(result));

//            contract.submitTransaction("createCar", "CAR10", "VW", "Polo", "Grey", "Mary");
//
//            result = contract.evaluateTransaction("queryCar", "CAR10");
//            System.out.println(new String(result));
//
//            contract.submitTransaction("changeCarOwner", "CAR10", "Archie");
//
//            result = contract.evaluateTransaction("queryCar", "CAR10");
//            System.out.println(new String(result));
        }
    }
}
