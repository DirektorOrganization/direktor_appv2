<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SyncInbox extends Model
{
    protected $table = 'sync_inbox';

    protected $fillable = [
        'company_id',
        'user_id',
        'device_id',
        'source',
        'entity_type',
        'entity_id',
        'operation_type',
        'client_mutation_id',
        'payload_json',
        'status',
        'retry_count',
        'received_at',
        'processing_at',
        'processed_at',
        'error_message',
    ];

    protected $casts = [
        'payload_json' => 'array',
        'received_at' => 'datetime',
        'processing_at' => 'datetime',
        'processed_at' => 'datetime',
    ];
}
