<?php

namespace App\Http\Controllers;

use App\Helpers\Mobile\SyncEntidades;
use App\Models\Anares_Area;
use App\Models\Proy_AreaIntegrante;
use App\Models\User;
use App\Services\ActaReuniones\Acuerdos\AcuerdosService2;
use App\Services\AnalisisRestricciones\ActividadService;
use App\Services\AnalisisRestricciones\AreasService;
use App\Services\AnalisisRestricciones\FaseService;
use App\Services\AnalisisRestricciones\FrenteService;
use App\Services\ControlHitos\DetalleHitosService;
use App\Services\ControlHitos\HitosGeneralService;
use Carbon\Carbon;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MobileController extends Controller
{
    public function pull(Request $request): JsonResponse
    {
        $request->validate([
            'userId' => ['required', 'integer'],
            'companyId' => ['required', 'string'],
            'scope' => ['required', 'in:full,operational'],
            'businessDate' => ['nullable', 'date'],
            'since' => ['nullable', 'date'],
        ]);

        $user = User::find($request->userId);

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Usuario no encontrado.',
            ], 404);
        }

        if (($user->nombreempresa ?? null) !== $request->companyId) {
            return response()->json([
                'success' => false,
                'message' => 'companyId no corresponde al usuario.',
            ], 422);
        }

        $company = DB::table('conf_maestro_empresas')
                    ->where('des_Empresa', $user->nombreempresa)
                    ->first();

        $now = Carbon::now();
        $nowIso = $now->toIso8601String();

        $projects = $this->getProjectsForUser($user->id, $nowIso);
        $projectIds = $projects->pluck('codProyecto')->values()->all();

        $response = [
            'success' => true,
            'scope' => $request->scope,
            'serverTime' => $nowIso,
            'businessDate' => $request->businessDate,
            'version' => $nowIso,
            'projects' => [],
            'restrictions' => [],
            'fronts' => [],
            'phases' => [],
            'meetings' => [],
            'agreements' => [],
            'milestoneControls' => [],
            'milestoneGenerals' => [],
            'milestones' => [],
            'milestoneDocuments' => [],
            'milestoneExtensions' => [],
            'actreu' => [
                'statusCategoria' => [],
                'statusSubcategoria' => [],
                'statusReuniones' => [],
                'statusAcuerdos' => [],
                'status_categoria' => [],
                'status_subcategoria' => [],
                'status_reuniones' => [],
                'status_acuerdos' => [],
                'actasReuniones' => [],
                'categorias' => [],
                'subcategorias' => [],
                'reuniones' => [],
                'participantes' => [],
                'grupoAcuerdos' => [],
                'acuerdos' => [],
                'acuerdosFoto' => [],
                'comentariosAcuerdo' => [],
                'asistencias' => [],
            ],
        ];

        if (empty($projectIds)) {
            return response()->json($response);
        }

        if ($request->scope === 'full') {
                $response['anares']['analysis'] = $this->getRestrictionModules($projectIds, $nowIso);
                $response['anares']['areas'] = $this->getAreas($company->cod_Empresa, $nowIso);
                $response['anares']['analysisAreas'] = $this->getAnalysisAreas($company->cod_Empresa, $nowIso);
                $response['anares']['types'] = $this->getTypes($nowIso);
                $response['anares']['statuses'] = $this->getStatuses($nowIso);
                $response['anares']['members'] = $this->getMembers($projectIds, $nowIso);
                $actreuStatus      = $this->getActreuStatusMasters($nowIso);
                $response['actreu']['status_categoria'] = $actreuStatus['status_categoria'];
                $response['actreu']['status_subcategoria'] = $actreuStatus['status_subcategoria'];
                $response['actreu']['status_reuniones'] = $actreuStatus['status_reuniones'];
                $response['actreu']['status_acuerdos'] = $actreuStatus['status_acuerdos'];
                $response['conthit']['milestoneTypes'] = $this->getMilestoneTypes($nowIso);
                $response['conthit']['milestoneClassifications'] = $this->getMilestoneClassifications($nowIso);
                $response['conthit']['milestoneStatusesInterno'] = $this->getMilestoneStatusesInterno($nowIso);
                $response['conthit']['milestoneStatusesContractual'] = $this->getMilestoneStatusesContractual($nowIso);
        }

        $response['projects'] = $projects->values();
        $response['restrictions'] = $this->getRestrictions($projectIds, $now);
        $response['fronts'] = $this->getFronts($projectIds, $nowIso);
        $response['phases'] = $this->getPhases($projectIds, $nowIso);
        $response['meetings'] = $this->getMeetings($projectIds, $nowIso);
        $response['agreements'] = $this->getAgreements($projectIds, $now);
        $response['actreu']['actasReuniones'] = $this->getActasReuniones($projectIds, $nowIso);
        $response['actreu']['categorias'] = $this->getCategorias($projectIds, $nowIso);
        $response['actreu']['subcategorias'] = $this->getSubcategorias($projectIds, $nowIso);
        $response['actreu']['reuniones'] = $this->getMeetings($projectIds, $nowIso);
        $response['actreu']['participantes'] = $this->getParticipants($projectIds, $nowIso);
        $response['actreu']['grupoAcuerdos'] = $this->getGrupoAcuerdos($projectIds, $nowIso);
        $response['actreu']['acuerdos'] = $this->getAgreements($projectIds, $now);
        $response['actreu']['acuerdosFoto'] = $this->getAcuerdosFoto($projectIds, $nowIso);
        $response['actreu']['comentariosAcuerdo'] = $this->getComentariosAcuerdo($projectIds, $nowIso);
        $response['actreu']['asistencias'] = $this->getAsistencias($projectIds, $nowIso);
        $response['milestoneControls'] = $this->getMilestoneControls($projectIds, $nowIso);
        $response['milestoneGenerals'] = $this->getMilestoneGenerals($projectIds, $nowIso);
        $response['milestones'] = $this->getMilestones($projectIds, $nowIso);
        $response['milestoneDocuments'] = $this->getMilestoneDocuments($projectIds, $nowIso);
        $response['milestoneExtensions'] = $this->getMilestoneExtensions($projectIds, $nowIso);
        \Log::info(json_encode($response));
        return response()->json($response, 200);
    }

    private function getProjectsForUser(int $userId, string $nowIso)
    {
        $projects = DB::table('proy_proyecto as proy')
            ->join('conf_maestro_empresas as emp', 'emp.cod_Empresa', '=', 'proy.cod_Empresa')
            ->leftJoin('conf_moneda as moneda', 'moneda.codMoneda', '=', 'proy.codMoneda')
            ->leftJoin('proy_tipoproyecto as tproy', 'tproy.codTipoProyecto', '=', 'proy.codTipoProyecto')
            ->leftJoin('conf_ubigeo as ubi', 'ubi.codUbigeo', '=', 'proy.codUbigeo')
            ->leftJoin('proy_integrantes as proyint', 'proyint.codProyecto', '=', 'proy.codProyecto')
            ->where(function ($q) use ($userId) {
                $q->where('proyint.idIntegrante', $userId)
                    ->orWhere('proy.id', $userId);
            })->where('proy.codEstado', 0)
            ->select([
                'proy.codProyecto',
                'proy.desNombreProyecto',
                'proy.codEstado',
                'proy.cod_Empresa',
                'emp.des_Empresa',
                'proy.codTipoProyecto',
                'tproy.desTipoProyecto',
                'proy.codMoneda',
                'moneda.desMoneda',
                'moneda.desSimbolo as desSimboloMoneda',
                'proy.codUbigeo',
                'ubi.desUbigeo',
                'proy.desDireccion',
                'proy.dayFechaInicio',
            ])
            ->distinct()
            ->orderBy('proy.codProyecto')
            ->get();

        $firstId = optional($projects->first())->codProyecto;

        return $projects->map(function ($project) use ($firstId, $nowIso) {
            $project->is_last_selected = $project->codProyecto == $firstId ? 1 : 0;
            $project->updated_at = $nowIso;
            $project->deleted = false;
            return $project;
        });
    }

    private function getRestrictionModules(array $projectIds, string $nowIso)
    {
        return DB::table('anares_analisisrestricciones')
            ->whereIn('codProyecto', $projectIds)
            ->select([
                'codAnaRes',
                'codProyecto',
                'codEstado',
                'dayFechaCreacion',
                'desUsuarioCreacion',
            ])
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getAnalysisAreas(string $companyId, string $nowIso)
    {
        return DB::table('anares_analisisrestriccionesarea as anaarea')
            ->leftJoin('proy_proyecto as proy', 'proy.codProyecto', '=', 'anaarea.codProyecto')
            ->selectRaw('
                anaarea.codAnaresArea,
                anaarea.codArea,
                anaarea.desArea,
                proy.cod_Empresa,
                anaarea.bgColor,
                anaarea.codProyecto
            ')
            ->where('proy.cod_Empresa', $companyId)
            ->distinct()
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getAreas(string $companyId, string $nowIso)
    {
        return Proy_AreaIntegrante::select(['codArea', 'desArea'])
            ->where(function ($query) use ($companyId) {
                $query->whereNull('cod_Empresa')
                    ->orWhere('cod_Empresa', $companyId);
            })
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getFronts(array $projectIds, string $nowIso)
    {
        return DB::table('anares_frente')
            ->whereIn('codProyecto', $projectIds)
            ->select(['codAnaresFrente', 'codProyecto', 'codAnares', 'desAnaresFrente'])
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getPhases(array $projectIds, string $nowIso)
    {
        return DB::table('anares_fase')
            ->whereIn('codProyecto', $projectIds)
            ->select(['codAnaresFase', 'codAnaresFrente', 'codProyecto', 'codAnares', 'desAnaresFase', 'bgColor'])
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getActasReuniones(array $projectIds, string $nowIso)
    {
        return DB::table('actreu_actareuniones')
            ->whereIn('codProyecto', $projectIds)
            ->select([
                'codActReu',
                'codProyecto',
                'codEstado',
                'dayFechaCreacion',
                'desUsuarioCreacion',
            ])
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getCategorias(array $projectIds, string $nowIso)
    {
        return DB::table('actreu_categoria')
            ->whereIn('codProyecto', $projectIds)
            ->select([
                'codActReuCategoria',
                'codProyecto',
                'codActReu',
                'desNombreCategoria',
                'dayFechaCreacion',
                'desUsuarioCreacion',
                'dayFechaModificacion',
                'desUsuarioModificacion',
                'codEstado',
            ])
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getSubcategorias(array $projectIds, string $nowIso)
    {
        return DB::table('actreu_subcategoria')
            ->whereIn('codProyecto', $projectIds)
            ->select([
                'codActReuSubCategoria',
                'codProyecto',
                'codActReu',
                'codActReuCategoria',
                'codEstado',
                'desNombreSubCategoria',
                'dayFechaCreacion',
                'desUsuarioCreacion',
                'dayFechaModificacion',
                'desUsuarioModificacion',
            ])
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getGrupoAcuerdos(array $projectIds, string $nowIso)
    {
        return DB::table('actreu_grupoacuerdo')
            ->where(function ($query) use ($projectIds) {
                $query->whereIn('codProyecto', $projectIds)
                    ->orWhereNull('codProyecto');
            })
            ->select([
                'codActReuGrupoAcuerdo',
                'codProyecto',
                'desGrupoAcuerdo',
                'desColorGrupoAcuerdo',
                'codOptionalArea',
            ])
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getAcuerdosFoto(array $projectIds, string $nowIso)
    {
        return DB::table('actreu_acuerdosfoto as foto')
            ->join('actreu_reuniones as reu', 'foto.codActReuReuniones', '=', 'reu.codActReuReuniones')
            ->join('actreu_subcategoria as sub', 'reu.codActReuSubCategoria', '=', 'sub.codActReuSubCategoria')
            ->leftJoin('actreu_categoria as cat', 'sub.codActReuCategoria', '=', 'cat.codActReuCategoria')
            ->select([
                'foto.codActReuAcuerdosFoto',
                DB::raw('sub.codProyecto as codProyecto'),
                DB::raw('sub.codActReu as codActReu'),
                DB::raw('cat.codActReuCategoria as codActReuCategoria'),
                DB::raw('sub.codActReuSubCategoria as codActReuSubCategoria'),
                'foto.codActReuAcuerdos',
                'foto.codActReuReuniones',
                'foto.desAcuerdo',
                DB::raw("DATE_FORMAT(foto.dayFechaAcuerdo, '%Y-%m-%d') as dayFechaAcuerdo"),
                DB::raw("DATE_FORMAT(foto.dayFechaAplazo, '%Y-%m-%d') as dayFechaAplazo"),
                DB::raw("DATE_FORMAT(foto.dayFechaLevantamiento, '%Y-%m-%d') as dayFechaLevantamiento"),
                'foto.numAplazos',
                'foto.idUsuarioResponsable',
                'foto.codGrupoAcuerdo',
                'foto.codEstado',
                'foto.numOrden',
                'foto.dayFechaCreacion',
                'foto.desUsuarioCreacion',
                'foto.dayFechaModificacion',
                'foto.desUsuarioModificacion',
            ])
            ->whereIn('sub.codProyecto', $projectIds)
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getComentariosAcuerdo(array $projectIds, string $nowIso)
    {
        return DB::table('actreu_comentarios_acuerdo as com')
            ->join('actreu_acuerdos as acu', 'com.codActReuAcuerdos', '=', 'acu.codActReuAcuerdos')
            ->join('actreu_reuniones as reu', 'acu.codActReuReuniones', '=', 'reu.codActReuReuniones')
            ->join('actreu_subcategoria as sub', 'reu.codActReuSubCategoria', '=', 'sub.codActReuSubCategoria')
            ->leftJoin('actreu_categoria as cat', 'sub.codActReuCategoria', '=', 'cat.codActReuCategoria')
            ->select([
                'com.codComentario',
                DB::raw('sub.codProyecto as codProyecto'),
                DB::raw('sub.codActReu as codActReu'),
                DB::raw('cat.codActReuCategoria as codActReuCategoria'),
                DB::raw('sub.codActReuSubCategoria as codActReuSubCategoria'),
                DB::raw('reu.codActReuReuniones as codActReuReuniones'),
                'com.codActReuAcuerdos',
                'com.codComentarioPadre',
                'com.idUsuario',
                'com.desMensaje',
                'com.dayFechaComentario',
                'com.desUsuarioCreacion',
                'com.dayFechaModificacion',
                'com.desUsuarioModificacion',
            ])
            ->whereIn('sub.codProyecto', $projectIds)
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getAsistencias(array $projectIds, string $nowIso)
    {
        return DB::table('actreu_asistencias as asi')
            ->join('actreu_reuniones as reu', 'asi.codActReuReuniones', '=', 'reu.codActReuReuniones')
            ->join('actreu_subcategoria as sub', 'reu.codActReuSubCategoria', '=', 'sub.codActReuSubCategoria')
            ->leftJoin('actreu_categoria as cat', 'sub.codActReuCategoria', '=', 'cat.codActReuCategoria')
            ->select([
                'asi.codActReuAsistencia',
                DB::raw('sub.codProyecto as codProyecto'),
                DB::raw('sub.codActReu as codActReu'),
                DB::raw('cat.codActReuCategoria as codActReuCategoria'),
                DB::raw('sub.codActReuSubCategoria as codActReuSubCategoria'),
                'asi.codActReuReuniones',
                'asi.codEstado',
                'asi.desNombre',
                'asi.desCorreoElectronico',
                'asi.idUsuarioParticipante',
                'asi.codProyIntegrante',
                'asi.codActReuParticipante',
                'asi.desJustificacion',
                'asi.dayFechaCreacion',
                'asi.desUsuarioCreacion',
                'asi.dayFechaModificacion',
                'asi.desUsuarioModificacion',
            ])
            ->whereIn('sub.codProyecto', $projectIds)
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getTypes(string $nowIso)
    {
        return DB::table('anares_tiporestricciones')
            ->select(['codTipoRestricciones', 'desTipoRestricciones'])
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getStatuses(string $nowIso): array
    {
        return [
            [
                'codEstado' => 1,
                'desEstado' => 'Pendiente',
                'iconColor' => '#98A3B3',
                'codModulo' => 1,
                'codElementoControl' => 1,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
            [
                'codEstado' => 2,
                'desEstado' => 'En proceso',
                'iconColor' => '#F0A11E',
                'codModulo' => 1,
                'codElementoControl' => 2,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
            [
                'codEstado' => 3,
                'desEstado' => 'Completado',
                'iconColor' => '#1B8E5A',
                'codModulo' => 1,
                'codElementoControl' => 3,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
        ];
    }

    private function getActreuStatusMasters(string $nowIso): array
    {
        return [
            'status_categoria' => [
                [
                    'codEstado' => 1,
                    'desEstado' => 'Activo',
                    'updated_at' => $nowIso,
                    'deleted' => false,
                ],
            ],
            'status_subcategoria' => [
                [
                    'codEstado' => 1,
                    'desEstado' => 'En Progreso',
                    'updated_at' => $nowIso,
                    'deleted' => false,
                ],
                [
                    'codEstado' => 2,
                    'desEstado' => 'Finalizado',
                    'updated_at' => $nowIso,
                    'deleted' => false,
                ],
            ],
            'status_reuniones' => [
                [
                    'codEstado' => 1,
                    'desEstado' => 'Programada',
                    'updated_at' => $nowIso,
                    'deleted' => false,
                ],
                [
                    'codEstado' => 2,
                    'desEstado' => 'Finalizado',
                    'updated_at' => $nowIso,
                    'deleted' => false,
                ],
                [
                    'codEstado' => 3,
                    'desEstado' => 'Retrasado',
                    'updated_at' => $nowIso,
                    'deleted' => false,
                ],
            ],
            'status_acuerdos' => [
                [
                    'codEstado' => 1,
                    'desEstado' => 'En Progreso',
                    'updated_at' => $nowIso,
                    'deleted' => false,
                ],
                [
                    'codEstado' => 2,
                    'desEstado' => 'Aplazado',
                    'updated_at' => $nowIso,
                    'deleted' => false,
                ],
                [
                    'codEstado' => 3,
                    'desEstado' => 'Finalizado acuerdo',
                    'updated_at' => $nowIso,
                    'deleted' => false,
                ],
                [
                    'codEstado' => 4,
                    'desEstado' => 'Atrasado',
                    'updated_at' => $nowIso,
                    'deleted' => false,
                ],
                [
                    'codEstado' => 6,
                    'desEstado' => 'Informativo',
                    'updated_at' => $nowIso,
                    'deleted' => false,
                ],
            ],
        ];
    }

    private function getMembers(array $projectIds, string $nowIso)
    {
        return DB::table('proy_integrantes as proyint')
            ->leftJoin('proy_areaintegrante as proyarea', 'proyint.codArea', '=', 'proyarea.codArea')
            ->leftJoin('proy_rolintegrante as rol', 'proyint.codRolIntegrante', '=', 'rol.codRolIntegrante')
            ->whereIn('proyint.codProyecto', $projectIds)
            ->select([
                'proyint.codProyIntegrante',
                'proyint.codProyecto',
                DB::raw('proyint.idIntegrante as user_id'),
                'proyint.codArea',
                'proyarea.desArea',
                'proyint.codRolIntegrante',
                'rol.desRolIntegrante',
                'proyint.codEstadoInvitacion',
                'proyint.desCorreo',
                'proyint.numCelular',
            ])
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getRestrictions(array $projectIds, Carbon $now)
    {
        $today = $now->copy()->startOfDay();
        $nowIso = $now->toIso8601String();

        return DB::table('anares_actividad as act')
            ->join('anares_frente as frente', 'act.codAnaresFrente', '=', 'frente.codAnaresFrente')
            ->leftJoin('anares_fase as fase', 'act.codAnaresFase', '=', 'fase.codAnaresFase')
            ->leftJoin('anares_tiporestricciones as tr', 'act.codTipoRestriccion', '=', 'tr.codTipoRestricciones')
            ->leftJoin('proy_integrantes as integrante', 'act.idUsuarioResponsable', '=', 'integrante.codProyIntegrante')
            ->leftJoin('users as uresp', 'integrante.idIntegrante', '=', 'uresp.id')
            ->leftJoin('users as usol', 'act.codUsuarioSolicitante', '=', 'usol.id')
            ->whereIn('frente.codProyecto', $projectIds)
            ->select([
                'act.codAnaResActividad',
                'frente.codProyecto',
                'frente.codAnares',
                DB::raw('act.codAnaresFrente as codAnaresFrente'),
                DB::raw('act.codAnaresFase as codAnaresFase'),
                DB::raw("COALESCE(frente.desAnaresFrente, '-') as desFrente"),
                DB::raw("COALESCE(fase.desAnaresFase, '-') as desFase"),
                'act.desActividad',
                'act.desRestriccion',
                'act.codTipoRestriccion',
                DB::raw('tr.desTipoRestricciones as desTipoRestriccion'),
                DB::raw("DATE_FORMAT(act.dayFechaRequerida, '%Y-%m-%d') as dayFechaRequerida"),
                DB::raw("DATE_FORMAT(act.dayFechaConciliada, '%Y-%m-%d') as dayFechaConciliada"),
                DB::raw('NULL as dayFechaLevantamiento'),
                'act.idUsuarioResponsable',
                DB::raw("
                    COALESCE(
                        CONCAT(uresp.name, ' ', uresp.lastname),
                        uresp.email,
                        integrante.desCorreo,
                        'Sin responsable'
                    ) as desResponsable
                "),
                'act.codEstadoActividad',
                DB::raw("
                    CASE
                        WHEN act.codEstadoActividad = 1 THEN 'Pendiente'
                        WHEN act.codEstadoActividad = 2 THEN 'En proceso'
                        WHEN act.codEstadoActividad = 3 THEN 'Completado'
                        ELSE '-'
                    END as desEstadoActividad
                "),
                DB::raw("
                    CASE
                        WHEN act.codEstadoActividad = 1 THEN '#98A3B3'
                        WHEN act.codEstadoActividad = 2 THEN '#F0A11E'
                        WHEN act.codEstadoActividad = 3 THEN '#1B8E5A'
                        ELSE '#98A3B3'
                    END as colorEstado
                "),
                DB::raw('act.codArea as codAnaresArea'),
                'act.codUsuarioSolicitante',
                DB::raw("TRIM(CONCAT(COALESCE(usol.name, ''), ' ', COALESCE(usol.lastname, ''))) as desSolicitante"),
                'act.dayFechaCreacion',
                'act.dayFechaModificacion',
            ])
            ->get()
            ->map(function ($row) use ($today, $nowIso) {
                $row->updated_at = $nowIso;
                $row->deleted = false;
                $row->is_completed = 0;
                $row->is_overdue = 0;
                $row->is_due_today = 0;
                $row->is_pending = 0;
                $row->is_in_progress = 0;
                $row->priority_order = 3;

                if ((int) $row->codEstadoActividad === 3) {
                    $row->is_completed = 1;
                    return $row;
                }

                if ((int) $row->codEstadoActividad === 1) {
                    $row->is_pending = 1;
                }

                if ((int) $row->codEstadoActividad === 2) {
                    $row->is_in_progress = 1;
                }

                $targetDate = Carbon::parse($row->dayFechaConciliada ?: $row->dayFechaRequerida)->startOfDay();

                if ($targetDate->lt($today)) {
                    $row->is_overdue = 1;
                } elseif ($targetDate->eq($today)) {
                    $row->is_due_today = 1;
                }

                return $row;
            });
    }

    private function getMeetings(array $projectIds, string $nowIso)
    {
        return DB::table('actreu_reuniones as reu')
            ->join('actreu_subcategoria as sub', 'reu.codActReuSubCategoria', '=', 'sub.codActReuSubCategoria')
            ->join('actreu_categoria as cat', 'sub.codActReuCategoria', '=', 'cat.codActReuCategoria')
            ->join('actreu_actareuniones as act', 'act.codActReu', '=', 'sub.codActReu')
            ->whereIn('sub.codProyecto', $projectIds)
            ->where('act.codEstado', 0)
            ->select([
                'reu.codActReuReuniones',
                'sub.codProyecto',
                'sub.codActReu',
                'cat.codActReuCategoria',
                'sub.codActReuSubCategoria',
                'cat.desNombreCategoria',
                'sub.desNombreSubCategoria',
                'reu.desNombre',
                DB::raw("DATE_FORMAT(reu.dayFechaReunion, '%Y-%m-%d') as dayFechaReunion"),
                DB::raw("DATE_FORMAT(reu.dayFechaCierre, '%Y-%m-%d') as dayFechaCierre"),
                'reu.horHoraInicio',
                'reu.horHoraFin',
                'reu.codEstado',
                DB::raw("
                    CASE
                        WHEN reu.codEstado = 1 THEN 'Programada'
                        WHEN reu.codEstado = 2 THEN 'Finalizado'
                        WHEN reu.codEstado = 3 THEN 'Retrasado'
                        ELSE '-'
                    END as desEstado
                "),
                'reu.desLinkActaReunion',
            ])
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getParticipants(array $projectIds, string $nowIso)
    {
        return DB::table('actreu_participantes as part')
            ->join('actreu_subcategoria as sub', 'part.codActReuSubCategoria', '=', 'sub.codActReuSubCategoria')
            ->leftJoin('actreu_categoria as cat', 'sub.codActReuCategoria', '=', 'cat.codActReuCategoria')
            ->whereIn('sub.codProyecto', $projectIds)
            ->select([
                'part.codActReuParticipante',
                'sub.codProyecto',
                DB::raw('sub.codActReu as codActReu'),
                DB::raw('cat.codActReuCategoria as codActReuCategoria'),
                'sub.codActReuSubCategoria',
                'part.idUsuarioParticipante',
                'part.codProyIntegrante',
                'part.desNombre',
                'part.desCorreoElectronico',
                'part.codArea',
                'part.flgParticipanteInvitado',
                'part.codEstado',
                'part.dayFechaCreacion',
                'part.desUsuarioCreacion',
            ])
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getAgreements(array $projectIds, Carbon $now)
    {
        $today = $now->copy()->startOfDay();
        $nowIso = $now->toIso8601String();

        return DB::table('actreu_acuerdos as acu')
            ->join('actreu_reuniones as reu', 'acu.codActReuReuniones', '=', 'reu.codActReuReuniones')
            ->join('actreu_subcategoria as sub', 'reu.codActReuSubCategoria', '=', 'sub.codActReuSubCategoria')
            ->leftJoin('actreu_categoria as cat', 'sub.codActReuCategoria', '=', 'cat.codActReuCategoria')
            ->leftJoin('actreu_grupoacuerdo as ga', 'acu.codGrupoAcuerdo', '=', 'ga.codActReuGrupoAcuerdo')
            ->leftJoin('actreu_participantes as part', 'acu.idUsuarioResponsable', '=', 'part.idUsuarioParticipante')
            ->join('actreu_actareuniones as act', 'act.codActReu', '=', 'sub.codActReu')
            ->whereIn('sub.codProyecto', $projectIds)
            ->where('act.codEstado', 0)
            ->select([
                'acu.codActReuAcuerdos',
                'acu.codActReuReuniones',
                'sub.codProyecto',
                DB::raw('sub.codActReu as codActReu'),
                DB::raw('cat.codActReuCategoria as codActReuCategoria'),
                DB::raw('sub.codActReuSubCategoria as codActReuSubCategoria'),
                'acu.desAcuerdo',
                DB::raw("DATE_FORMAT(acu.dayFechaAcuerdo, '%Y-%m-%d') as dayFechaAcuerdo"),
                DB::raw("DATE_FORMAT(acu.dayFechaAplazo, '%Y-%m-%d') as dayFechaAplazo"),
                DB::raw("DATE_FORMAT(acu.dayFechaLevantamiento, '%Y-%m-%d') as dayFechaLevantamiento"),
                'acu.numAplazos',
                'acu.idUsuarioResponsable',
                DB::raw("COALESCE(part.desNombre, part.desCorreoElectronico, 'Sin responsable') as desResponsable"),
                'acu.codEstado',
                DB::raw("
                    CASE
                        WHEN acu.codEstado = 1 THEN 'En Progreso'
                        WHEN acu.codEstado = 2 THEN 'Aplazado'
                        WHEN acu.codEstado = 3 THEN 'Finalizado acuerdo'
                        WHEN acu.codEstado = 4 THEN 'Atrasado'
                        WHEN acu.codEstado = 6 THEN 'Informativo'
                        ELSE '-'
                    END as desEstado
                "),
                'acu.codGrupoAcuerdo',
                'ga.desGrupoAcuerdo',
                'ga.desColorGrupoAcuerdo',
                'acu.numOrden',
                'acu.numOrdenAnteriores',
                'acu.dayFechaCreacion',
                'acu.desUsuarioCreacion',
                'acu.dayFechaModificacion',
                'acu.desUsuarioModificacion',
            ])
            ->get()
            ->map(function ($row) use ($today, $nowIso) {
                $row->updated_at = $nowIso;
                $row->deleted = false;
                $row->is_completed = 0;
                $row->is_overdue = 0;
                $row->is_due_today = 0;
                $row->is_pending = 0;

                if (in_array((int) $row->codEstado, [3, 6], true)) {
                    $row->is_completed = 1;
                    return $row;
                }

                if (in_array((int) $row->codEstado, [1, 2, 4], true)) {
                    $row->is_pending = 1;
                }

                $targetDate = Carbon::parse($row->dayFechaAplazo ?: $row->dayFechaAcuerdo)->startOfDay();

                if ($targetDate->lt($today)) {
                    $row->is_overdue = 1;
                } elseif ($targetDate->eq($today)) {
                    $row->is_due_today = 1;
                }

                return $row;
            });
    }


    private function appendMeta($row, string $nowIso)
    {
        $row->updated_at = $row->updated_at ?? $nowIso;
        $row->deleted = false;
        return $row;
    }

    private function getMilestoneTypes(string $nowIso)
    {
        return [
            [
                'codTipoHito' => 1,
                'desTipoHito' => 'Contractual',
                'orden' => 1,
                'codEstado' => 1,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
            [
                'codTipoHito' => 2,
                'desTipoHito' => 'Interno',
                'orden' => 2,
                'codEstado' => 1,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
        ];
    }

    private function getMilestoneClassifications(string $nowIso)
    {
        return [
            [
                'codTipoClasificacion' => 1,
                'desTipoClasificacion' => 'De Control',
                'orden' => 1,
                'codEstado' => 1,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
            [
                'codTipoClasificacion' => 2,
                'desTipoClasificacion' => 'Penalizable',
                'orden' => 2,
                'codEstado' => 1,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
        ];
    }

    private function getMilestoneStatusesInterno(string $nowIso)
    {
        return [
            [
                'codEstado' => 1,
                'desEstado' => 'En progreso',
                'desColor' => '#F0A11E',
                'desIcono' => 'timelapse',
                'orden' => 1,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
            [
                'codEstado' => 2,
                'desEstado' => 'Retrasado',
                'desColor' => '#D64545',
                'desIcono' => 'warning',
                'orden' => 2,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
            [
                'codEstado' => 3,
                'desEstado' => 'Completado',
                'desColor' => '#1B8E5A',
                'desIcono' => 'check_circle',
                'orden' => 3,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
        ];
    }

    private function getMilestoneStatusesContractual(string $nowIso)
    {
        return [
            [
                'codEstado' => 1,
                'desEstado' => 'En progreso',
                'desColor' => '#F0A11E',
                'desIcono' => 'timelapse',
                'orden' => 1,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
            [
                'codEstado' => 2,
                'desEstado' => 'Retrasado',
                'desColor' => '#D64545',
                'desIcono' => 'warning',
                'orden' => 2,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
            [
                'codEstado' => 3,
                'desEstado' => 'Completado',
                'desColor' => '#1B8E5A',
                'desIcono' => 'check_circle',
                'orden' => 3,
                'updated_at' => $nowIso,
                'deleted' => false,
            ],
        ];
    }

    private function getMilestoneControls(array $projectIds, string $nowIso)
    {
        return DB::table('conhit_controlhitos')
            ->select(['codConHit', 'codProyecto', 'codEstado', 'dayFechaCreacion', 'desUsuarioCreacion'])
            ->whereIn('codProyecto', $projectIds)
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getMilestoneGenerals(array $projectIds, string $nowIso)
    {
        return DB::table('conhit_general as gen')
            ->leftJoin('conhit_controlhitos as ch', 'gen.codConHit', '=', 'ch.codConHit')
            ->select([
                'gen.codConHitGeneral',
                'gen.codConHit',
                'gen.codProyecto',
                'gen.numDiasPlazoTotal',
                'gen.mntTotal',
                'gen.numDias',
                'gen.codEstado',
                'gen.dayFechaInicioContractual',
                'gen.dayFechaCreacion',
                'gen.desUsuarioCreacion',
                'gen.dayFechaModificacion',
                'gen.desUsuarioModificacion',
            ])
            ->whereIn('gen.codProyecto', $projectIds)
            ->where('ch.codEstado', 0)
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getMilestones(array $projectIds, string $nowIso)
    {
        return DB::table('conhit_detallehitos as det')
            ->leftJoin('conhit_controlhitos as ch', 'det.codConHit', '=', 'ch.codConHit')
            ->select([
                'det.codConHitDetalleHitos',
                'det.codConHit',
                'det.codProyecto',
                'det.codConHitGeneral',
                'det.NumOrden',
                'det.desDescripcion',
                'det.codTipoHito',
                'det.codTipoClasificacion',
                'det.numplazo',
                'det.porPenalidad',
                'det.dayFechaContractual',
                'det.dayFechaMeta',
                'det.numCantAmpContractual',
                'det.numCantAmpMeta',
                'det.dayFechaReal',
                'det.desLinkDocuCierre',
                'det.codEstadoContractual',
                'det.codEstadoInternos',
                'det.mntPealidad',
                'det.dayFechaCreacion',
                'det.desUsuarioCreacion',
                'det.dayFechaModificacion',
                'det.desUsuarioModificacion',
                'det.dayFechaContractualAmp',
                'det.dayFechaMetaAmp',
            ])
            ->whereIn('det.codProyecto', $projectIds)
            ->where('ch.codEstado', 0)
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getMilestoneDocuments(array $projectIds, string $nowIso)
    {
        return DB::table('conhit_archivosfechareal as docs')
            ->join('conhit_detallehitos as deth', 'docs.codConHitDetalleHitos', '=', 'deth.codConHitDetalleHitos')
            ->leftJoin('conhit_controlhitos as ch', 'deth.codConHit', '=', 'ch.codConHit')
            ->select([
                'docs.codConhitArchivosFechaReal',
                'docs.codConHitDetalleHitos',
                'docs.desNombreArchivo',
                'docs.desRutaArchivo',
                'docs.dayFechaCreacion',
                'docs.desUsuarioCreacion',
                'docs.dayFechaModificacion',
                'docs.desUsuarioModifcacion',
            ])
            ->whereIn('deth.codProyecto', $projectIds)
            ->where('ch.codEstado', 0)
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }

    private function getMilestoneExtensions(array $projectIds, string $nowIso)
    {
        return DB::table('conthit_detallehitosamp as dethamp')
            ->join('conhit_detallehitos as deth', 'dethamp.codConHitDetalleHitos', '=', 'deth.codConHitDetalleHitos')
            ->leftJoin('conhit_controlhitos as ch', 'deth.codConHit', '=', 'ch.codConHit')
            ->select([
                'dethamp.codConHitDetalleHitosAmp',
                'dethamp.codConHitDetalleHitos',
                'dethamp.desMotivo',
                'dethamp.dayFechaMeta',
                'dethamp.dayFechaContractual',
                'dethamp.desLinklDocuAmp',
                'dethamp.dayFechaCreacion',
                'dethamp.desUsuarioCreacion',
                'dethamp.dayFechaModificacion',
                'dethamp.desUsuarioModificacion',
                'dethamp.desTipoFecha',
            ])
            ->whereIn('deth.codProyecto', $projectIds)
            ->where('ch.codEstado', 0)
            ->get()
            ->map(fn ($row) => $this->appendMeta($row, $nowIso));
    }




    public function insert(Request $request) {
        try {
            $userId = $request->userId;
            $entidad = SyncEntidades::traducirEntidad($request->entidad);
            $columnas = SyncEntidades::obtenerColumnasActualizacion($entidad['tabla']);
            $datosInsert = [];
            if (is_string($request->payload)) {
                $request->payload = json_decode($request->payload);
            }
            foreach ($columnas as $columna) {
                if (isset($request->payload->$columna)) {
                    $datosInsert[$columna] = $request->payload->$columna;
                }
            }
            switch ($entidad['tabla']) {
                case 'anares_actividad':
                    $service = app(ActividadService::class);
                    $service->insertarRestriccionMobile($datosInsert, $userId);
                    break;
                case 'anares_analisisrestriccionesarea':
                    $service = app(AreasService::class);
                    $service->insertarAreaMobile($datosInsert);
                    break;
                case 'anares_fase':
                    $service = app(FaseService::class);
                    $service->insertarFaseMobile($datosInsert);
                    break;
                case 'anares_frente':
                    $service = app(FrenteService::class);
                    $service->insertarFrenteMobile($datosInsert);
                    break;
                case 'actreu_acuerdos':
                    break;
                case 'conhit_detallehitos':
                    $service = app(DetalleHitosService::class);
                    $service->insertarDetalleHitoMobile($datosInsert);
                    break;
                case 'conthit_detallehitosamp':
                    $service = app(DetalleHitosService::class);
                    $service->insertarDetalleHitosAmp($datosInsert);
                    break;
                default:
                    throw new Exception('Entidad no implementada');
            }
            return response()->json([
                'message' => 'OK'
            ], 200);
        } catch (\Throwable $th) {
            return response()->json([
                'message' => $th->getMessage()
            ], 500);
        }
    }

    public function update(Request $request) {
        try {
            $entidad = SyncEntidades::traducirEntidad($request->entidad);
            $columnasModificables = SyncEntidades::obtenerColumnasActualizacion($entidad['tabla']);
            $datosUpdate = [];
            if (is_string($request->payload)) {
                $request->payload = json_decode($request->payload);
            }
            foreach ($columnasModificables as $columna) {
                if (isset($request->payload->$columna)) {
                    $datosUpdate[$columna] = $request->payload->$columna;
                }
            }

            switch ($entidad['tabla']) {
                case 'anares_actividad':
                    $service = app(ActividadService::class);
                    $service->actualizarRestriccionMobile($datosUpdate);
                    break;
                case 'actreu_acuerdos':
                    $service = app(AcuerdosService2::class);
                    $service->actualizarAcuerdoMobile($datosUpdate);
                    break;
                case 'conhit_general':
                    $service = app(HitosGeneralService::class);
                    $service->editarHitoGeneral($datosUpdate);
                    break;
                case 'conhit_detallehitos':
                    $service = app(DetalleHitosService::class);
                    $service->actualizarDetalleHitoMobile($datosUpdate);
                    break;
                default:
                    throw new Exception('Entidad no implementada');
            }
            return response()->json([
                'message' => 'OK'
            ], 200);
        } catch (\Throwable $th) {
            return response()->json([
                'message' => $th->getMessage()
            ], 500);
        }
    }

    public function delete(Request $request){
        try {
            //$userId = $request->userId;
            $entidad = SyncEntidades::traducirEntidad($request->entidad);
            $idEntidad = $request->idEntidad;
            if (is_string($request->payload)) {
                $request->payload = json_decode($request->payload);
            }
            switch ($entidad['tabla']) {
                case 'anares_actividad':
                    $codProyecto = $request->payload->codProyecto;
                    $service = app(ActividadService::class);
                    $service->eliminarRestriccion($idEntidad, $codProyecto);
                    break;
                case 'actreu_acuerdos':
                    break;
                case 'conhit_detallehitos':
                    $codProyecto = $request->payload->codProyecto;
                    $service = app(DetalleHitosService::class);
                    $service->eliminarDetalleHito($idEntidad, $codProyecto);
                    break;
                default:
                    throw new Exception('Entidad no implementada');
            }
            return response()->json([
                'message' => 'OK'
            ], 200);
        } catch (\Throwable $th) {
            return response()->json([
                'message' => $th->getMessage()
            ], 500);
        }
    }
}
