<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Voucher extends Model
{
    use HasFactory, BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'partner_name',
        'code',
        'amount',
        'status',
        'order_id',
        'order_code',
        'used_by_name',
        'used_by_phone',
        'used_at',
        'is_reported',
        'reported_at',
        'notes',
    ];

    protected $casts = [
        'amount' => 'integer',
        'is_reported' => 'boolean',
        'used_at' => 'datetime',
        'reported_at' => 'datetime',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }
}
