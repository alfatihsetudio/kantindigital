<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Table extends Model
{
    use HasFactory;

    protected $fillable = ['code', 'name', 'is_occupied'];

    protected $casts = [
        'is_occupied' => 'boolean',
    ];

    public function orders()
    {
        return $this->hasMany(Order::class);
    }
}

