<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class QrisSetting extends Model
{
    use HasFactory, BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'merchant_name',
        'merchant_city',
        'whatsapp_number',
        'base_payload',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];
}
