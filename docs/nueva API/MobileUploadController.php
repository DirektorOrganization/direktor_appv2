<?php

namespace App\Http\Controllers;

use App\Http\Requests\MobileUploadRequest;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class MobileUploadController extends Controller
{
    public function store(MobileUploadRequest $request): JsonResponse
    {
        $user = User::find($request->integer('userId'));

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Usuario no encontrado.',
            ], 404);
        }

        if (($user->nombreempresa ?? null) !== $request->string('companyId')->toString()) {
            return response()->json([
                'success' => false,
                'message' => 'companyId no corresponde al usuario.',
            ], 422);
        }

        $file = $request->file('file');
        $now = Carbon::now('America/Lima');
        $extension = strtolower($file->getClientOriginalExtension() ?: $file->extension() ?: 'bin');
        $fileToken = sprintf(
            'mob_%s_%s_%s',
            $user->id,
            $now->format('Ymd_His'),
            Str::lower(Str::random(8))
        );
        $fileName = $fileToken . '.' . $extension;
        $directory = sprintf(
            'mobile_uploads/%s/%s/%s/%s',
            $request->string('companyId')->toString(),
            Str::slug($request->string('module')->toString(), '_'),
            Str::slug($request->string('entityType')->toString(), '_'),
            $now->format('Y/m/d')
        );
        $filePath = $file->storeAs($directory, $fileName, 'public');
        $fileUrl = Storage::disk('public')->url($filePath);

        // Tabla opcional de auditoria.
        DB::table('mobile_uploaded_files')->insert([
            'fileToken' => $fileToken,
            'userId' => $user->id,
            'companyId' => $request->string('companyId')->toString(),
            'module' => $request->string('module')->toString(),
            'entityType' => $request->string('entityType')->toString(),
            'entityId' => $request->input('entityId'),
            'originalName' => $file->getClientOriginalName(),
            'fileName' => $fileName,
            'filePath' => $filePath,
            'fileUrl' => $fileUrl,
            'mimeType' => $file->getMimeType(),
            'extension' => $extension,
            'size' => $file->getSize(),
            'dayFechaCreacion' => $now->toDateTimeString(),
            'desUsuarioCreacion' => $user->email ?? ('user_' . $user->id),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Archivo cargado correctamente.',
            'data' => [
                'fileToken' => $fileToken,
                'originalName' => $file->getClientOriginalName(),
                'fileName' => $fileName,
                'filePath' => $filePath,
                'fileUrl' => $fileUrl,
                'mimeType' => $file->getMimeType(),
                'extension' => $extension,
                'size' => $file->getSize(),
                'module' => $request->string('module')->toString(),
                'entityType' => $request->string('entityType')->toString(),
                'entityId' => $request->input('entityId'),
                'uploadedAt' => $now->toIso8601String(),
            ],
        ]);
    }
}
