package com.lemon.app.ui

import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.lemon.app.R
import com.lemon.app.data.TotpEntry
import com.lemon.app.totp.Totp

/**
 * Live TOTP codes. The lemon timer animates itself; this adapter only swaps
 * the code text when the 30s window rolls over, so nothing rebinds every
 * second (that was what made the list stutter).
 */
class TotpAdapter(
    private val items: MutableList<TotpEntry>,
    private val onCopy: (TotpEntry) -> Unit,
    private val onEdit: (TotpEntry) -> Unit,
    private val onDelete: (TotpEntry) -> Unit
) : RecyclerView.Adapter<TotpAdapter.VH>() {

    class VH(view: View) : RecyclerView.ViewHolder(view) {
        val label: TextView = view.findViewById(R.id.totp_label)
        val issuer: TextView = view.findViewById(R.id.totp_issuer)
        val code: TextView = view.findViewById(R.id.totp_code)
        val timer: LemonTimerView = view.findViewById(R.id.totp_timer)
        val copy: ImageButton = view.findViewById(R.id.totp_copy)
        val edit: ImageButton = view.findViewById(R.id.totp_edit)
        val delete: ImageButton = view.findViewById(R.id.totp_delete)
        var boundCounter: Long = -1
    }

    private val holders = ArrayList<VH>()
    private val handler = Handler(Looper.getMainLooper())

    private val ticker = object : Runnable {
        override fun run() {
            val now = System.currentTimeMillis()
            for (i in holders.indices.reversed()) {
                val vh = holders[i]
                val pos = vh.adapterPosition
                if (pos == RecyclerView.NO_POSITION || pos >= items.size) continue
                bindDynamic(vh, items[pos], now)
            }
            handler.postDelayed(this, 200L)
        }
    }

    fun start() {
        handler.removeCallbacks(ticker)
        handler.post(ticker)
    }

    fun stop() {
        handler.removeCallbacks(ticker)
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
        holder.issuer.visibility = if (entry.issuer.isBlank()) View.GONE else View.VISIBLE
        holder.timer.periodSeconds = entry.period
        holder.boundCounter = -1
        bindDynamic(holder, entry, System.currentTimeMillis())

        holder.itemView.setOnClickListener { onCopy(entry) }
        holder.copy.setOnClickListener { onCopy(entry) }
        holder.edit.setOnClickListener { onEdit(entry) }
        holder.delete.setOnClickListener { onDelete(entry) }

        if (!holders.contains(holder)) holders.add(holder)
    }

    override fun onViewRecycled(holder: VH) {
        holders.remove(holder)
        super.onViewRecycled(holder)
    }

    private fun bindDynamic(holder: VH, entry: TotpEntry, now: Long) {
        val counter = now / 1000L / entry.period
        if (counter == holder.boundCounter) return
        holder.boundCounter = counter

        val code = Totp.pretty(
            Totp.code(
                entry.secret,
                timeMillis = now,
                period = entry.period,
                digits = entry.digits,
                algorithm = entry.algorithm
            )
        )
        if (holder.code.text.toString() != code) {
            holder.code.text = code
            holder.code.animate().cancel()
            holder.code.alpha = 0.35f
            holder.code.animate().alpha(1f).setDuration(240).start()
        }
        val remaining = Totp.secondsRemaining(entry.period)
        holder.timer.contentDescription =
            holder.timer.context.getString(R.string.totp_timer_desc) + " " + remaining
    }

    fun refresh() = notifyDataSetChanged()
}
