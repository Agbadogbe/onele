<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\StoreMaterielRequest;
use App\Http\Resources\MaterielResource;
use App\Models\Materiel;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;

class MaterielController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(): JsonResponse
    {
        return response()->json(MaterielResource::collection(Materiel::orderBy('nom')->get()));
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreMaterielRequest $request): JsonResponse
    {
        $materiel = Materiel::create($request->validated());

        return response()->json(new MaterielResource($materiel), Response::HTTP_CREATED);
    }

    /**
     * Display the specified resource.
     */
    public function show(Materiel $materiel): JsonResponse
    {
        return response()->json(new MaterielResource($materiel));
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(StoreMaterielRequest $request, Materiel $materiel): JsonResponse
    {
        $materiel->update($request->validated());

        return response()->json(new MaterielResource($materiel));
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Materiel $materiel): JsonResponse
    {
        $materiel->delete();

        return response()->json(null, Response::HTTP_NO_CONTENT);
    }
}
