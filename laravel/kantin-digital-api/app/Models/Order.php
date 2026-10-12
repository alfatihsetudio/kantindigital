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
        'payment_method', 'total_amount', 'discount_amount',
        'voucher_code', 'voucher_discount_amount',
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
}
