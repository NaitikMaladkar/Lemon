package com.lemon.app.data

/**
 * Pre-built decoy data for Pseudo mode (opened by any wrong PIN).
 */
object SeedData {

    fun pseudo(out: MutableList<VaultEntry>, totps: MutableList<TotpEntry>) {
        out.addAll(
            listOf(
                VaultEntry(title = "Gmail", username = "lemon.user@gmail.com", secret = "SweetLemon@12", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Facebook", username = "lemon.user@gmail.com", secret = "Mango#42Lemon", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Netflix", username = "binge@lemonmail.com", secret = "CitrusSlice99", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Amazon", username = "shop@lemonmail.com", secret = "Basket2024!", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Spotify", username = "tunes@lemonmail.com", secret = "lemon-honey-melon-zest", type = VaultEntry.TYPE_PASSPHRASE),
                VaultEntry(title = "Instagram", username = "@lemonlover", secret = "Sunbeam_77", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Bank of Maharashtra", username = "lemonraj", secret = "BankPass!2024", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Paytm Wallet", username = "98765 43210", secret = "Wallet@123", type = VaultEntry.TYPE_PASSWORD)
            )
        )
        totps.addAll(
            listOf(
                TotpEntry(label = "Google", issuer = "Google", secret = "JBSWY3DPEHPK3PXP"),
                TotpEntry(label = "Microsoft", issuer = "Microsoft", secret = "KRSXG5DSMVZGI2LD")
            )
        )
    }
}
