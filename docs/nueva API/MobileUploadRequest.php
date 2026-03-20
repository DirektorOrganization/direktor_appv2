<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class MobileUploadRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'userId' => ['required', 'integer'],
            'companyId' => ['required', 'string', 'max:100'],
            'module' => ['required', 'string', 'max:100'],
            'entityType' => ['required', 'string', 'max:100'],
            'entityId' => ['nullable', 'string', 'max:100'],
            'file' => [
                'required',
                'file',
                'max:10240',
                'mimes:pdf,doc,docx,jpg,jpeg,png,webp',
            ],
        ];
    }

    public function messages(): array
    {
        return [
            'file.max' => 'El archivo no debe superar los 10 MB.',
            'file.mimes' => 'Solo se permiten PDF, Word e imagenes.',
        ];
    }
}
