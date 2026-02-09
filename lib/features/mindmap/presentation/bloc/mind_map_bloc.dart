import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../domain/models/mind_map_node.dart';
import '../../domain/repositories/mind_map_repository.dart';

part 'mind_map_event.dart';
part 'mind_map_state.dart';

@injectable
class MindMapBloc extends Bloc<MindMapEvent, MindMapState> {
  final MindMapRepository _repository;

  MindMapBloc(this._repository) : super(const MindMapInitial()) {
    on<LoadMindMaps>(_onLoadMindMaps);
    on<SaveMindMap>(_onSaveMindMap);
    on<DeleteMindMap>(_onDeleteMindMap);
    on<AddNode>(_onAddNode);
    on<UpdateNode>(_onUpdateNode);
    on<DeleteNode>(_onDeleteNode);
    on<SelectMindMap>(_onSelectMindMap);
  }

  Future<void> _onLoadMindMaps(
    LoadMindMaps event,
    Emitter<MindMapState> emit,
  ) async {
    emit(const MindMapLoading());
    try {
      final mindMaps = await _repository.getMindMaps();
      emit(
        MindMapLoaded(
          mindMaps: mindMaps,
          selectedMindMap: mindMaps.isNotEmpty ? mindMaps.first : null,
        ),
      );
    } catch (e) {
      emit(MindMapError(e.toString()));
    }
  }

  Future<void> _onSaveMindMap(
    SaveMindMap event,
    Emitter<MindMapState> emit,
  ) async {
    try {
      await _repository.saveMindMap(event.node);
      final currentState = state;
      if (currentState is MindMapLoaded) {
        final mindMaps = await _repository.getMindMaps();
        final exists = mindMaps.any((m) => m.id == event.node.id);
        final selectedMindMap =
            exists
                ? mindMaps.firstWhere((m) => m.id == event.node.id)
                : (mindMaps.isNotEmpty ? mindMaps.first : null);
        emit(
          MindMapLoaded(mindMaps: mindMaps, selectedMindMap: selectedMindMap),
        );
      } else {
        add(const LoadMindMaps());
      }
    } catch (e) {
      emit(MindMapError(e.toString()));
    }
  }

  Future<void> _onDeleteMindMap(
    DeleteMindMap event,
    Emitter<MindMapState> emit,
  ) async {
    try {
      await _repository.deleteMindMap(event.id);
      add(const LoadMindMaps());
    } catch (e) {
      emit(MindMapError(e.toString()));
    }
  }

  Future<void> _onAddNode(AddNode event, Emitter<MindMapState> emit) async {
    final currentState = state;
    if (currentState is! MindMapLoaded) return;

    try {
      final updatedMindMap = currentState.selectedMindMap!.addChild(
        event.parentId,
        event.node,
      );
      await _repository.saveMindMap(updatedMindMap);
      final mindMaps = await _repository.getMindMaps();
      final selectedMindMap = mindMaps.firstWhere(
        (m) => m.id == updatedMindMap.id,
        orElse: () => mindMaps.first,
      );
      emit(MindMapLoaded(mindMaps: mindMaps, selectedMindMap: selectedMindMap));
    } catch (e) {
      emit(MindMapError(e.toString()));
    }
  }

  Future<void> _onUpdateNode(
    UpdateNode event,
    Emitter<MindMapState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MindMapLoaded) return;

    try {
      final updatedMindMap = currentState.selectedMindMap!.updateNode(
        event.nodeId,
        (node) => node.copyWith(
          label: event.newLabel ?? node.label,
          colorValue: event.newColor?.toARGB32() ?? node.colorValue,
          x: event.newX ?? node.x,
          y: event.newY ?? node.y,
        ),
      );
      await _repository.saveMindMap(updatedMindMap);
      final mindMaps = await _repository.getMindMaps();
      MindMapNode? selectedMindMap;
      try {
        selectedMindMap = mindMaps.firstWhere((m) => m.id == updatedMindMap.id);
      } catch (_) {
        selectedMindMap = mindMaps.isNotEmpty ? mindMaps.first : null;
      }
      emit(MindMapLoaded(mindMaps: mindMaps, selectedMindMap: selectedMindMap));
    } catch (e) {
      emit(MindMapError(e.toString()));
    }
  }

  Future<void> _onDeleteNode(
    DeleteNode event,
    Emitter<MindMapState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MindMapLoaded) return;

    try {
      final currentMindMap = currentState.selectedMindMap;
      if (currentMindMap == null) return;

      // Eğer root node siliniyorsa, tüm mind map'i sil
      if (currentMindMap.id == event.nodeId) {
        await _repository.deleteMindMap(event.nodeId);
        final mindMaps = await _repository.getMindMaps();
        final selectedMindMap = mindMaps.isNotEmpty ? mindMaps.first : null;
        emit(
          MindMapLoaded(mindMaps: mindMaps, selectedMindMap: selectedMindMap),
        );
        return;
      }

      // Child node sil
      final updatedMindMap = currentMindMap.removeChild(event.nodeId);
      await _repository.saveMindMap(updatedMindMap);
      final mindMaps = await _repository.getMindMaps();
      MindMapNode? selectedMindMap;
      try {
        selectedMindMap = mindMaps.firstWhere((m) => m.id == updatedMindMap.id);
      } catch (_) {
        selectedMindMap = mindMaps.isNotEmpty ? mindMaps.first : null;
      }
      emit(MindMapLoaded(mindMaps: mindMaps, selectedMindMap: selectedMindMap));
    } catch (e) {
      emit(MindMapError(e.toString()));
    }
  }

  Future<void> _onSelectMindMap(
    SelectMindMap event,
    Emitter<MindMapState> emit,
  ) async {
    final currentState = state;
    if (currentState is MindMapLoaded) {
      emit(currentState.copyWith(selectedMindMap: event.node));
    }
  }
}
