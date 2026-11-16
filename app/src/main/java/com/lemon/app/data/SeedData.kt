package com.lemon.app.data

/**
 * Pre-built decoy data. Pseudo mode shows an obviously fake list; Secret mode
 * shows a more polished, "nearly real" looking list. Neither contains the real
 * vault.
 */
object SeedData {

    fun pseudo(out: MutableList<VaultEntry>, totps: MutableList<TotpEntry>) {
        out.addAll(
            listOf(
                VaultEntry(title = "Gmail", username = "lemon.user@gmail.com", secret = "SweetLemon@12", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Facebook", username = "lemon.user@gmail.com", secret = "Mango#42Lemon", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Netflix", username = "binge@lemonmail.com", secret = "CitrusSlice99", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Amazon", username = "shop@lemonmail.com", secret = "Basket2024!", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Spotify", username = "tunes@lemonmail.com", secret = "LemonadeVibes", type = VaultEntry.TYPE_PASSPHRASE),
                VaultEntry(title = "Instagram", username = "@lemonlover", secret = "Sunbeam_77", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "X (Twitter)", username = "@lemontweety", secret = "CitrusChirp", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Bank of Maharashtra", username = "lemonraj", secret = "BankPass!2024", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Paytm Wallet", username = "98765 43210", secret = "Wallet@123", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Phone Backup PIN", username = "", secret = "4829", type = VaultEntry.TYPE_PASSPHRASE)
            )
        )
        totps.addAll(
            listOf(
                TotpEntry(label = "Google", issuer = "Google", secret = "JBSWY3DPEHPK3PXP"),
                TotpEntry(label = "Microsoft", issuer = "Microsoft", secret = "KRSXG5DSMVZGI2LD")
            )
        )
    }

    fun secret(out: MutableList<VaultEntry>, totps: MutableList<TotpEntry>) {
        out.addAll(
            listOf(
                VaultEntry(title = "Gmail (Personal)", username = "raj.lemonkar@gmail.com", secret = "R4tnagiri!Lemon#2024", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "HDFC Bank", username = "raj.lemonkar", secret = "NetBanking#88", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Income Tax Portal", username = "PAN ABCPL1234F", secret = "TaxFiling@2024", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "LinkedIn", username = "raj.lemonkar", secret = "MarketLemon!9", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "Dropbox", username = "raj.lemonkar@gmail.com", secret = "CloudSlice_2024", type = VaultEntry.TYPE_PASSPHRASE),
                VaultEntry(title = "WhatsApp Web", username = "+91 98220 12345", secret = "WaLemonWeb!", type = VaultEntry.TYPE_PASSWORD),
                VaultEntry(title = "iCloud", username = "raj.lemonkar@icloud.com", secret = "AppleLemonPie3", type = VaultEntry.TYPE_PASSPHRASE),
                VaultEntry(title = "GitHub", username = "lemonraj", secret = "ghLemon!2024", type = VaultEntry.TYPE_PASSWORD)
            )
        )
        totps.addAll(
            listOf(
                TotpEntry(label = "Google", issuer = "Google", secret = "JBSWY3DPEHPK3PXP"),
                TotpEntry(label = "GitHub", issuer = "GitHub", secret = "KRSXG5DSMVZGI2LD")
            )
        )
    }
}
