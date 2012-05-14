//
//  gmodel.c
//  GlucoseMonitor
//
//  Created by Michael Toth on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//#import <UIKit/UIKit.h>
#include <stdio.h>
#include "gsl_vector.h"
#include "gsl_matrix.h"
#include <math.h>
/* gmodel.c -- model functions for glucose level */

#include "gmodel.h"

int
gmodel_f (const gsl_vector * x, void *data, 
        gsl_vector * f)
{
    size_t n = ((struct data *)data)->n;
    double *xArray = ((struct data *)data)->x;
    double *y = ((struct data *)data)->y;
    //double *sigma = ((struct data *) data)->sigma;
    
    double Go = gsl_vector_get (x, 0);
    double A = gsl_vector_get (x, 1);
    double B = gsl_vector_get (x, 2);
    double C = gsl_vector_get (x, 3);
    
    size_t i;
    
    for (i = 0; i < n; i++)
    {
        /* Model Yi = Go + A * exp(-B * i)*i^C */
        double t = xArray[i];
        double Yi = A * exp (-B * t) * pow(t, C) + Go;
        //printf("Yi is %g, t is %g\n",Yi,t);
        gsl_vector_set (f, i, (Yi - y[i]));
    }
    
    return GSL_SUCCESS;
}

int
gmodel_df (const gsl_vector * x, void *data, 
         gsl_matrix * J)
{
    size_t n = ((struct data *)data)->n;
    double *xArray = ((struct data *)data)->x;

    //double *sigma = ((struct data *) data)->sigma;
    // f(x)=Go + A * e^(-B*x) * x^C
    // df(x)/dA = e^(-B*x) * x^C
    // df(x)/dB = A * x^C * (-x)*e^(-B*x)
    // df(x)/dC = A * e^(-B*x) * x^C * log(x)
    // df(x)/dGo = 1
    
    
    double A = gsl_vector_get (x, 1); // A
    double B = gsl_vector_get (x, 2); // B
    double C = gsl_vector_get (x, 3); // C
    
    size_t i;
    
    for (i = 0; i < n; i++)
    {
        /* Jacobian matrix J(i,j) = dfi / dxj, */
        /* where fi = (Yi - yi)/sigma[i],      */
        /*       Yi = Go + A * e^(-B*xi) * xi^C  */
        /* and the xj are the parameters (Go, A, B, C) */
        
        double t = xArray[i];
        double e = exp(-B*t)*pow(t,C);
        //printf("t is %g and e is %g",t,e);
        if (t==0) {
            gsl_matrix_set(J, i, 0, 1);
            gsl_matrix_set(J, i, 1, e);
            gsl_matrix_set(J, i, 2, 0);
            gsl_matrix_set(J, i, 3, 0);
        } else {
            gsl_matrix_set(J, i, 0, 1);
            gsl_matrix_set(J, i, 1, e);
            gsl_matrix_set(J, i, 2, A*e*(-t));
            gsl_matrix_set(J, i, 3, A*e*log(t));
        }
    }
    return GSL_SUCCESS;
}

int
gmodel_fdf (const gsl_vector * x, void *data,
          gsl_vector * f, gsl_matrix * J)
{
    gmodel_f(x, data, f);
    gmodel_df (x, data, J);
    
    return GSL_SUCCESS;
}



