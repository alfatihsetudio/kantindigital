<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory, BelongsToTenant;

    protected $fillable = [
        'tenant_id', 'code', 'customer_name', 'customer_phone',
        'table_id', 'order_type', 'delivery_address', 'status',
        'cashier_shift_report_id',
        'payment_method', 'total_amount', 'discount_amount',
        'voucher_code', 'voucher_discount_amount',
        'delivery_discount_amount',
    ];

    protected $casts = [
        'total_amount' => 'integer',
        'discount_amount' => 'integer',
        'voucher_discount_amount' => 'integer',
        'delivery_discount_amount' => 'integer',
    ];

    public function table()
    {
        return $this->belongsTo(Table::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function voucher()
    {
        return $this->hasOne(Voucher::class, 'order_id');
    }

    public function shiftReport()
    {
        return $this->belongsTo(CashierShiftReport::class, 'cashier_shift_report_id');
    }
}
