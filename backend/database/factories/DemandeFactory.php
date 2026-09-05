<?php

namespace Database\Factories;

use App\Models\Demande;
use App\Models\DemandeConge;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Demande>
 */
class DemandeFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $debut = fake()->dateTimeBetween('-1 month', '+1 month');

        return [
            'type' => 'conge',
            'date_debut' => $debut,
            'date_fin' => (clone $debut)->modify('+'.fake()->numberBetween(1, 5).' days'),
            'statut' => 'en_attente',
            'utilisateur_id' => User::factory(),
        ];
    }

    public function configure(): static
    {
        return $this->afterCreating(function (Demande $demande) {
            if ($demande->type === 'conge' && ! $demande->conge()->exists()) {
                DemandeConge::create([
                    'demande_id' => $demande->id,
                    'type_conge' => fake()->randomElement(['annuel', 'maladie', 'exceptionnel']),
                    'nombre_jours' => fake()->numberBetween(1, 10),
                ]);
            }
        });
    }

    public function validee(): static
    {
        return $this->state(fn (array $attributes) => [
            'statut' => 'validee',
        ]);
    }

    public function refusee(): static
    {
        return $this->state(fn (array $attributes) => [
            'statut' => 'refusee',
            'commentaire' => fake()->sentence(),
        ]);
    }
}
