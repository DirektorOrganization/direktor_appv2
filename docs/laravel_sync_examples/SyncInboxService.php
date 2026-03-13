<?php

namespace App\Services;

use App\Models\SyncInbox;
use Illuminate\Support\Facades\DB;

class SyncInboxService
{
    public function storeItems(array $data): array
    {
        $results = [];
        $accepted = 0;

        DB::transaction(function () use ($data, &$results, &$accepted) {
            foreach ($data['items'] as $item) {
                $existing = SyncInbox::where('client_mutation_id', $item['clientMutationId'])->first();

                if ($existing) {
                    $results[] = [
                        'clientMutationId' => $item['clientMutationId'],
                        'status' => 'duplicate',
                        'syncInboxId' => $existing->id,
                    ];
                    continue;
                }

                $row = SyncInbox::create([
                    'company_id' => auth()->user()?->company_id ?? null,
                    'user_id' => $data['userId'],
                    'device_id' => $data['deviceId'] ?? null,
                    'source' => $data['source'],
                    'entity_type' => $item['entityType'],
                    'entity_id' => $item['entityId'],
                    'operation_type' => $item['operationType'],
                    'client_mutation_id' => $item['clientMutationId'],
                    'payload_json' => $item['payload'],
                    'status' => 'pending',
                    'received_at' => now(),
                ]);

                $accepted++;

                $results[] = [
                    'clientMutationId' => $item['clientMutationId'],
                    'status' => 'accepted',
                    'syncInboxId' => $row->id,
                ];
            }
        });

        return [
            'accepted' => $accepted,
            'results' => $results,
        ];
    }
}
