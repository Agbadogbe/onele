<?php

namespace Database\Factories;

use App\Models\Materiel;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Materiel>
 */
class MaterielFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'nom' => fake()->randomElement(['Ordinateur portable', 'Casque audio', 'Vidéoprojecteur', 'Souris sans fil', 'Clavier', 'Écran 24"', 'Chaise ergonomique', 'Imprimante']),
            'categorie' => fake()->randomElement(['Informatique', 'Mobilier', 'Bureautique']),
            'description' => fake()->sentence(),
            'quantite_disponible' => fake()->numberBetween(0, 30),
        ];
    }
}
