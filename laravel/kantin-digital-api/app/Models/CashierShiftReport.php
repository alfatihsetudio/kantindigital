<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CashierShiftReport extends Model
{
    use BelongsToTenant, HasFactory;

    protected $fillable = [
        'tenant_id',
        'cashier_id',
        'shift_opened_at',
        'shift_closed_at',
        'total_orders',
        'total_cash_expected',
        'total_qris_expected',
        'total_sales_expected',
        'cash_received',
        'cash_difference',
        'status',
        'cashier_notes',
        'approved_by',
        'approved_at',
        'approval_notes',
    ];

    protected $casts = [
        'shift_opened_at' => 'datetime',
        'shift_closed_at' => 'datetime',
        'approved_at' => 'datetime',
        'total_orders' => 'integer',
        'total_cash_expected' => 'float',
        'total_qris_expected' => 'float',
        'total_sales_expected' => 'float',
        'cash_received' => 'float',
        'cash_difference' => 'float',
    ];

    public function cashier()
    {
        return $this->belongsTo(User::class, 'cashier_id');
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'cashier_shift_report_id');
    }
}
