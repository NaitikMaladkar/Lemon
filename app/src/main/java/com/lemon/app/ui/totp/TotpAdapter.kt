package com.lemon.app.ui.totp

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.PopupMenu
import android.widget.ProgressBar
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.lemon.app.R
import com.lemon.app.data.TotpEntry
import com.lemon.app.totp.Totp

class TotpAdapter(
    private val onCopy: (TotpEntry) -> Unit,
    private val onDelete: (TotpEntry) -> Unit
) : RecyclerView.Adapter<TotpAdapter.VH>() {

    private val items = ArrayList<TotpEntry>()

    fun submit(list: List<TotpEntry>) {
        items.clear()
        items.addAll(list)
        notifyDataSetChanged()
    }

    /** Called every second by the fragment to refresh codes and progress. */
    fun tick() {
        notifyItemRangeChanged(0, itemCount)
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
        holder.issuer.visibility = if (entry.issuer.isEmpty()) View.GONE else View.VISIBLE

        val code = Totp.code(
            entry.secret,
            period = entry.period,
            digits = entry.digits,
            algorithm = entry.algorithm
        )
        holder.code.text = Totp.pretty(code)
        holder.progress.max = entry.period
        holder.progress.progress = Totp.secondsRemaining(entry.period)

        holder.copy.setOnClickListener { onCopy(entry) }
        holder.more.setOnClickListener { v ->
            val menu = PopupMenu(v.context, v)
            menu.inflate(R.menu.menu_totp)
            menu.setOnMenuItemClickListener { onDelete(entry); true }
            menu.show()
        }
    }

    class VH(view: View) : RecyclerView.ViewHolder(view) {
        val label: TextView = view.findViewById(R.id.totp_label)
        val issuer: TextView = view.findViewById(R.id.totp_issuer)
        val code: TextView = view.findViewById(R.id.totp_code)
        val progress: ProgressBar = view.findViewById(R.id.totp_progress)
        val copy: ImageButton = view.findViewById(R.id.totp_copy)
        val more: ImageButton = view.findViewById(R.id.totp_more)
    }
}
