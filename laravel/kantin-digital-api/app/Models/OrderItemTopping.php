<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderItemTopping extends Model
{
    use HasFactory;

    protected $fillable = ['order_item_id', 'topping_id', 'topping_name', 'topping_price'];

    public function orderItem()
    {
        return $this->belongsTo(OrderItem::class);
    }
}

