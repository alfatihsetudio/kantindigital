<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Tenant extends Model
{
    use HasFactory;

    protected $fillable = [
        'subdomain', 'name', 'logo_url', 'primary_color',
        'address', 'meta_title', 'meta_description', 'meta_image',
        'phone', 'whatsapp', 'plan', 'expires_at', 'is_active',
    ];

    protected $casts = [
        'is_active'  => 'boolean',
        'expires_at' => 'datetime',
    ];

    public function getLogoUrlAttribute($value): ?string
    {
        if (empty($value)) return null;
        $path = parse_url($value, PHP_URL_PATH);
        if (!empty($path) && str_starts_with($path, '/uploads/')) {
            if (request()->hasHeader('host')) {
                return request()->getSchemeAndHttpHost() . $path;
            }
            return url(ltrim($path, '/'));
        }
        return $value;
    }

    public function categories() { return $this->hasMany(Category::class); }
    public function menus()      { return $this->hasMany(Menu::class); }
    public function users()      { return $this->hasMany(User::class); }
    public function orders()     { return $this->hasMany(Order::class); }
    public function tables()     { return $this->hasMany(Table::class); }
    public function toppings()   { return $this->hasMany(Topping::class); }
}
