<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CustomerBonusLog extends Model
{
    use HasFactory, BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'customer_bonus_id',
        'customer_phone',
        'order_id',
        'order_code',
        'type',
        'transaction_amount',
        'bonus_percent',
        'bonus_amount',
        'balance_after',
        'notes',
        'user_id',
    ];

    protected $casts = [
        'transaction_amount' => 'integer',
        'bonus_percent' => 'integer',
        'bonus_amount' => 'integer',
        'balance_after' => 'integer',
    ];

    public function customerBonus()
    {
        return $this->belongsTo(CustomerBonus::class, 'customer_bonus_id');
    }

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }
}
