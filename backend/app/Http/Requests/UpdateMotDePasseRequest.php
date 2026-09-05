<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

class UpdateMotDePasseRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * `current_password` vérifie le mot de passe actuel contre la garde
     * connectée : un jeton volé ne suffit donc pas à changer le mot de passe.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'mot_de_passe_actuel' => ['required', 'string', 'current_password:sanctum'],
            'mot_de_passe' => ['required', 'string', 'confirmed', Password::min(8)],
        ];
    }

    /**
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'mot_de_passe_actuel.current_password' => 'Le mot de passe actuel est incorrect.',
            'mot_de_passe.confirmed' => 'La confirmation ne correspond pas.',
        ];
    }

    /**
     * @return array<string, string>
     */
    public function attributes(): array
    {
        return [
            'mot_de_passe_actuel' => 'mot de passe actuel',
            'mot_de_passe' => 'nouveau mot de passe',
        ];
    }
}
