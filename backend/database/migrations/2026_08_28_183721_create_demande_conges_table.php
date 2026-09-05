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
        Schema::create('demande_conges', function (Blueprint $table) {
            $table->foreignId('demande_id')->primary()->constrained('demandes')->cascadeOnDelete();
            $table->enum('type_conge', ['annuel', 'maladie', 'exceptionnel']);
            $table->unsignedSmallInteger('nombre_jours');
            $table->string('piece_jointe')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('demande_conges');
    }
};
