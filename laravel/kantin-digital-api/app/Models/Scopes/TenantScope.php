<?php

namespace App\Models\Scopes;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

class TenantScope implements Scope
{
    public function apply(Builder $builder, Model $model): void
    {
        if (app()->has('tenant')) {
            $tenant = app('tenant');
            $builder->where($model->getTable().'.tenant_id', $tenant->id);
        } else {
            $builder->whereNull($model->getTable().'.tenant_id');
        }
    }
}
