package com.lemon.app.ui

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.ProgressBar
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.lemon.app.R
import com.lemon.app.data.TotpEntry
import com.lemon.app.totp.Totp

/**
 * Live TOTP codes: code + countdown ring for every account.
 */
class TotpAdapter(
    private val items: MutableList<TotpEntry>,
    private val onCopy: (TotpEntry) -> Unit,
    private val onMore: (TotpEntry) -> Unit
) : RecyclerView.Adapter<TotpAdapter.VH>() {

    class VH(view: View) : RecyclerView.ViewHolder(view) {
        val label: TextView = view.findViewById(R.id.totp_label)
        val issuer: TextView = view.findViewById(R.id.totp_issuer)
        val code: TextView = view.findViewById(R.id.totp_code)
        val progress: ProgressBar = view.findViewById(R.id.totp_progress)
        val copy: ImageButton = view.findViewById(R.id.totp_copy)
        val more: ImageButton = view.findViewById(R.id.totp_more)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_totp, parent, false)
        return VH(view)
    }

    override fun getItemCount(): Int = items.size

    override fun onBindViewHolder(holder: VH, position: Int) {
        val entry = items[position]
        holder.label.text = entry.label
        holder.issuer.text = entry.issuer
        holder.code.text = Totp.pretty(
            Totp.code(
                entry.secret,
                period = entry.period,
                digits = entry.digits,
                algorithm = entry.algorithm
            )
        )
        val remaining = Totp.secondsRemaining(entry.period)
        holder.progress.max = entry.period
        holder.progress.progress = remaining
        holder.copy.setOnClickListener { onCopy(entry) }
        holder.more.setOnClickListener { onMore(entry) }
    }

    fun refresh() = notifyDataSetChanged()
}
