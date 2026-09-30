<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MenuTopping extends Model
{
    use HasFactory;

    protected $fillable = ['menu_id', 'topping_id', 'min', 'max'];

    public function menu()
    {
        return $this->belongsTo(Menu::class);
    }

    public function topping()
    {
        return $this->belongsTo(Topping::class);
    }
}

