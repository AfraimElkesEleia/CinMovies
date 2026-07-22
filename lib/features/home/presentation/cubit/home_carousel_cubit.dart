import 'package:flutter_bloc/flutter_bloc.dart';

class HomeCarouselCubit extends Cubit<int> {
  HomeCarouselCubit() : super(0);

  void setIndex(int index) => emit(index);
}
