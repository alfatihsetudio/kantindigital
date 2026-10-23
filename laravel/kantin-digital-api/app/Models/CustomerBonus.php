<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CustomerBonus extends Model
{
    use HasFactory, BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'customer_phone',
        'customer_name',
        'bonus_percent',
        'is_active',
        'notes',
        'total_orders',
        'total_spend',
        'total_bonus_earned',
        'total_bonus_claimed',
        'bonus_balance',
        'last_order_at',
    ];

    protected $casts = [
        'bonus_percent' => 'integer',
        'is_active' => 'boolean',
        'total_orders' => 'integer',
        'total_spend' => 'integer',
        'total_bonus_earned' => 'integer',
        'total_bonus_claimed' => 'integer',
        'bonus_balance' => 'integer',
        'last_order_at' => 'datetime',
    ];

    public function logs()
    {
        return $this->hasMany(CustomerBonusLog::class, 'customer_bonus_id')->orderByDesc('id');
    }

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }
}
