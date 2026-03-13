<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SyncInboxRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'userId' => ['required', 'integer'],
            'deviceId' => ['nullable', 'string', 'max:120'],
            'source' => ['required', 'string', 'max:50'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.entityType' => ['required', 'string', 'max:50'],
            'items.*.entityId' => ['required', 'string', 'max:100'],
            'items.*.operationType' => ['required', 'string', 'max:50'],
            'items.*.clientMutationId' => ['required', 'string', 'max:150'],
            'items.*.payload' => ['required', 'array'],
        ];
    }
}
