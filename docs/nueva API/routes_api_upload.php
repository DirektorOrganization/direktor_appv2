<?php

use App\Http\Controllers\MobileUploadController;
use Illuminate\Support\Facades\Route;

Route::post('/mobile/upload-file', [MobileUploadController::class, 'store']);
