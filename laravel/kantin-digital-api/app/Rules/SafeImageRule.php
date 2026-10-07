<?php

namespace App\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Http\UploadedFile;

class SafeImageRule implements ValidationRule
{
    protected int $maxKb;
    protected array $allowedExtensions;

    public function __construct(int $maxKb = 5120, array $allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'])
    {
        $this->maxKb = $maxKb;
        $this->allowedExtensions = array_map('strtolower', $allowedExtensions);
    }

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if ($value === null || $value === '') {
            return;
        }

        if (! $value instanceof UploadedFile) {
            $fail('File gambar tidak valid.');
            return;
        }

        if (! $value->isValid()) {
            $fail('Gagal mengunggah file gambar: '.$value->getErrorMessage());
            return;
        }

        if ($value->getSize() > $this->maxKb * 1024) {
            $limitText = $this->maxKb >= 1024 ? round($this->maxKb / 1024, 1).'MB' : $this->maxKb.'KB';
            $fail('Ukuran gambar maksimal '.$limitText.'.');
            return;
        }

        $ext = strtolower($value->getClientOriginalExtension());
        if (! in_array($ext, $this->allowedExtensions, true)) {
            $fail('Format gambar harus berupa: '.implode(', ', array_unique(array_map('strtoupper', $this->allowedExtensions))).'.');
            return;
        }

        $realPath = $value->getRealPath();
        if ($realPath && file_exists($realPath)) {
            $imgInfo = @getimagesize($realPath);
            if ($imgInfo === false && $ext !== 'webp') {
                $fail('File yang diunggah bukan file gambar yang valid.');
            }
        }
    }
}
