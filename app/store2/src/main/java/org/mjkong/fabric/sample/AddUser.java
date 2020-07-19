package org.mjkong.fabric.sample;

import org.hyperledger.fabric.gateway.Wallet;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class AddUser {
    public static void main(String[] args) {

        try {
            // A wallet stores a collection of identities
            Path walletPath = Paths.get("wallet");
            Wallet wallet = Wallet.createFileSystemWallet(walletPath);

            // Location of credentials to be stored in the wallet
            Path credentialPath = Paths.get("..", ".." ,"crypto-config",
                    "peerOrganizations", "store2.mymarket.com", "users", "User1@store2.mymarket.com", "msp");
            Path certificatePem = credentialPath.resolve(Paths.get("signcerts",
                    "User1@store2.mymarket.com-cert.pem"));
            Path privateKey = credentialPath.resolve(Paths.get("keystore",
                    "priv_sk"));

            // Load credentials into wallet
            String identityLabel = "User1@store2.mymarket.com";
            Wallet.Identity identity = Wallet.Identity.createIdentity("Store2MSP", Files.newBufferedReader(certificatePem), Files.newBufferedReader(privateKey));

            wallet.put(identityLabel, identity);

        } catch (IOException e) {
            System.err.println("Error adding to wallet");
            e.printStackTrace();
        }
    }
}
