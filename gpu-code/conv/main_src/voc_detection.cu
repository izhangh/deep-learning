///
///  \file conv3.cu
///

#include <iostream>
#include <fstream>
#include <sstream>
#include <cmath>
#include <omp.h>
#include "mpi.h"
#include "train_detection.hpp"
#include "convnet.hpp"

using namespace std;


typedef void(*loadFun)(); 

int Param::_minibatch_size = 0;

void managerNode(TrainDetection<float> *model){

	cout << "Loading data...\n";
	model->createWBiasForManager();
	cout << "Initialize weight and bias...\n";
	model->createPixelAndCoord();
	cout << "Loading data is done.\n";
	model->createMPIDist();
	cout << "done12\n";
	model->initWeightAndBcast();
	cout << "done13\n";
	model->sendAndRecvForManager();
	cout << "CPU number: " << omp_get_num_procs() << endl;  
}

void detectionNode(TrainDetection<float> *model){

	cout << "Initialize layers...\n";

	model->createLayerForWorker();
	cout << "Initialize layers is done.\n";
	model->createWBiasForWorker();
	cout << "done2\n";
	model->createPixelAndCoord();
	cout << "done3\n";
	model->createYDEDYForWorker();
	cout << "done4\n";
	model->createMPIDist();
	cout << "done5\n";
	model->initWeightAndBcast();
	cout << "done6\n";
	model->train();

}

int main(int argc, char** argv){

	int pid; 
	int num_process;
	int prov;
	MPI_Init_thread(&argc,&argv,MPI_THREAD_MULTIPLE, &prov);
	if (prov < MPI_THREAD_MULTIPLE)
	{   
		printf("Error: the MPI library doesn't provide the required thread level\n");
		MPI_Abort(MPI_COMM_WORLD, 0); 
	}   
	MPI_Comm_rank(MPI_COMM_WORLD,&pid);
	MPI_Comm_size(MPI_COMM_WORLD,&num_process);

	if(num_process <= 1){
		printf("Error: process number must bigger than 1\n");
		MPI_Abort(MPI_COMM_WORLD, 0); 
	}

	//检测有几个gpu
	int num_gpu;
	cudaGetDeviceCount(&num_gpu);
	cudaSetDevice(pid % num_gpu);

	cout << num_gpu << endl;
	cout << num_process << endl;	

	TrainDetection<float> *voc_model = new TrainDetection<float>(0, pid);

	voc_model->parseNetJson("script/voc.json");
	voc_model->parseImgBinary(num_process);

	if(pid == 0){ 
		managerNode(voc_model);
	}   
	else{
		detectionNode(voc_model);
	}
	 	
	delete voc_model;
	MPI_Finalize();


	return 0;
}

















