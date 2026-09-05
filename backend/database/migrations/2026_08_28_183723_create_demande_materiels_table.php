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
        Schema::create('demande_materiels', function (Blueprint $table) {
            $table->foreignId('demande_id')->primary()->constrained('demandes')->cascadeOnDelete();
            $table->foreignId('materiel_id')->constrained('materiels')->cascadeOnDelete();
            $table->unsignedSmallInteger('quantite');
            $table->string('motif')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('demande_materiels');
    }
};
