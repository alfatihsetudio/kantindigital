<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockCheck extends Model
{
    use BelongsToTenant, HasFactory;

    protected $fillable = [
        'tenant_id',
        'user_id',
        'check_type',
        'check_date',
        'status',
        'total_items',
        'matched_items',
        'notes',
    ];

    protected $casts = [
        'check_date' => 'date',
        'total_items' => 'integer',
        'matched_items' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function items()
    {
        return $this->hasMany(StockCheckItem::class);
    }
}
