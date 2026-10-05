<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Tenant extends Model
{
    use HasFactory;

    protected $fillable = [
        'subdomain', 'name', 'menu_code_prefix', 'promo_badge_text', 'promo_message', 'logo_url', 'primary_color',
        'address', 'opening_hours', 'meta_title', 'meta_description', 'meta_image',
        'phone', 'whatsapp', 'plan', 'expires_at', 'is_active', 'is_store_open', 'store_opened_at',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'is_store_open' => 'boolean',
        'expires_at' => 'datetime',
    ];

    public function getLogoUrlAttribute($value): ?string
    {
        if (empty($value)) {
            return null;
        }
        $path = parse_url($value, PHP_URL_PATH);
        if (! empty($path) && str_starts_with($path, '/uploads/')) {
            $host = request()->header('x-forwarded-host') ?? request()->header('host') ?? request()->getHost();
            $scheme = (request()->isSecure() || request()->header('x-forwarded-proto') === 'https' || ! app()->isLocal()) ? 'https' : 'http';

            return "{$scheme}://{$host}{$path}";
        }

        return $value;
    }

    public function getMetaImageAttribute($value): ?string
    {
        if (empty($value)) {
            return null;
        }
        $path = parse_url($value, PHP_URL_PATH);
        if (! empty($path) && str_starts_with($path, '/uploads/')) {
            $host = request()->header('x-forwarded-host') ?? request()->header('host') ?? request()->getHost();
            $scheme = (request()->isSecure() || request()->header('x-forwarded-proto') === 'https' || ! app()->isLocal()) ? 'https' : 'http';

            return "{$scheme}://{$host}{$path}";
        }

        return $value;
    }

    public function categories()
    {
        return $this->hasMany(Category::class);
    }

    public function menus()
    {
        return $this->hasMany(Menu::class);
    }

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function tables()
    {
        return $this->hasMany(Table::class);
    }

    public function toppings()
    {
        return $this->hasMany(Topping::class);
    }
}
