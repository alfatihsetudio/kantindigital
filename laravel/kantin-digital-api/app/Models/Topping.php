<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Topping extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'price'];

    public function menuToppings()
    {
        return $this->hasMany(MenuTopping::class);
    }

    public function menus()
    {
        return $this->belongsToMany(Menu::class, 'menu_toppings')
                    ->withPivot('min', 'max')
                    ->withTimestamps();
    }
}

