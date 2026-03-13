<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\SyncInboxRequest;
use App\Services\SyncInboxService;
use Illuminate\Http\JsonResponse;

class SyncInboxController extends Controller
{
    public function __construct(
        private SyncInboxService $syncInboxService
    ) {
    }

    public function store(SyncInboxRequest $request): JsonResponse
    {
        $result = $this->syncInboxService->storeItems($request->validated());

        return response()->json([
            'success' => true,
            'accepted' => $result['accepted'],
            'receivedAt' => now()->toDateTimeString(),
            'results' => $result['results'],
        ]);
    }
}
