<?php

use App\Http\Controllers\Api\SyncInboxController;
use Illuminate\Support\Facades\Route;

Route::post('/sync/inbox', [SyncInboxController::class, 'store']);
