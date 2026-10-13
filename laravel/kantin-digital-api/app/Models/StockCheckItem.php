<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StockCheckItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'stock_check_id',
        'stock_item_id',
        'item_name',
        'unit',
        'whole_quantity',
        'remainder_quantity',
        'previous_whole_quantity',
        'previous_remainder_quantity',
        'difference_whole',
        'difference_remainder',
        'is_matched',
        'notes',
    ];

    protected $casts = [
        'whole_quantity' => 'float',
        'remainder_quantity' => 'float',
        'previous_whole_quantity' => 'float',
        'previous_remainder_quantity' => 'float',
        'difference_whole' => 'float',
        'difference_remainder' => 'float',
        'is_matched' => 'boolean',
    ];

    public function stockCheck()
    {
        return $this->belongsTo(StockCheck::class);
    }

    public function stockItem()
    {
        return $this->belongsTo(StockItem::class);
    }
}
