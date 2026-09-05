<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('demande_permissions', function (Blueprint $table) {
            $table->foreignId('demande_id')->primary()->constrained('demandes')->cascadeOnDelete();
            $table->time('heure_debut');
            $table->time('heure_fin');
            $table->string('motif');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('demande_permissions');
    }
};
