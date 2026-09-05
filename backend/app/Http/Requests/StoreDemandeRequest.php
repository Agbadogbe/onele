<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;

class StoreDemandeRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'type' => ['required', 'in:conge,permission,materiel'],
            'date_debut' => ['required', 'date'],
            'date_fin' => ['required', 'date', 'after_or_equal:date_debut'],

            'type_conge' => ['required_if:type,conge', 'in:annuel,maladie,exceptionnel'],
            'nombre_jours' => ['required_if:type,conge', 'integer', 'min:1'],
            'piece_jointe' => ['nullable', 'string'],

            'heure_debut' => ['required_if:type,permission', 'date_format:H:i'],
            'heure_fin' => ['required_if:type,permission', 'date_format:H:i', 'after:heure_debut'],
            'motif' => ['required_if:type,permission,materiel', 'string', 'max:255'],

            'materiel_id' => ['required_if:type,materiel', 'exists:materiels,id'],
            'quantite' => ['required_if:type,materiel', 'integer', 'min:1'],
        ];
    }
}
