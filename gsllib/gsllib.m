//
//  gsllib.m
//  gsllib
//
//  Created by Michael Toth on 4/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define NUM 120

#import "gsllib.h"
#import "gsl_matrix.h"
#import "gsl_vector.h"
#import "gsl_multifit.h"
#import "gsl_multifit_nlin.h"
#import "gmodel.h"
#import "gsl_rng.h"
#import "gsl_blas.h"
#include <math.h>


@implementation gsllib


- (NSArray *)getParams:(NSArray *)value num:(int)n {
    const gsl_multifit_fdfsolver_type *T;
    gsl_multifit_fdfsolver *s;
    int status;
    unsigned int i, iter = 0;
    const size_t p = 4;
    gsl_matrix *covar = gsl_matrix_alloc (p, p);
    double xArray[NUM],y[NUM];
    struct data d = { n, xArray, y};
    gsl_multifit_function_fdf f;
    double x_init[4] = { 80, 100, 4, 2.0 };
    gsl_vector_view x = gsl_vector_view_array (x_init, p);
    const gsl_rng_type * type;
    gsl_rng * r;
    
    /* This is the data to be fitted */
    for (i=0; i<n; i++) {
        xArray[i] = [[[value objectAtIndex:i] objectForKey:@"x"] doubleValue];
        y[i]=[[[value objectAtIndex:i] objectForKey:@"y"] doubleValue];
    }
    
    gsl_rng_env_setup();
    
    type = gsl_rng_default;
    r = gsl_rng_alloc (type);
    
    f.f = &gmodel_f;
    f.df = &gmodel_df;
    f.fdf = &gmodel_fdf;
    f.n = n;
    f.p = p;
    f.params = &d;
    
    T = gsl_multifit_fdfsolver_lmsder;
    s = gsl_multifit_fdfsolver_alloc (T, n, p);
    gsl_multifit_fdfsolver_set (s, &f, &x.vector);
    
    print_state (iter, s);
    
    do
    {
        iter++;
        status = gsl_multifit_fdfsolver_iterate (s);
        
        //printf ("status = %s\n", gsl_strerror (status));
        
        print_state (iter, s);
        
        if (status)
            break;
        
        status = gsl_multifit_test_delta (s->dx, s->x,
                                          1e-4, 1e-4);
    }
    while (status == GSL_CONTINUE && iter < 500);
    
    gsl_multifit_covar (s->J, 0.0, covar);
    
#define FIT(i) gsl_vector_get(s->x, i)
#define ERR(i) sqrt(gsl_matrix_get(covar,i,i))
    

        double Go,A,B,C;
        
        ////printf("chisq/dof = %g\n",  pow(chi, 2.0) / dof);
        
        Go=FIT(0);
        A=FIT(1);
        B=FIT(2);
        C=FIT(3);

        //printf ("Go      = %.5f +/- %.5f\n", Go, c*ERR(0));
        //printf ("A       = %.5f +/- %.5f\n", A, c*ERR(1));
        //printf ("B       = %.5f +/- %.5f\n", B, c*ERR(2));
        //printf ("C       = %.5f +/- %.5f\n", C, c*ERR(3));
    
    
    //printf ("status = %s\n", gsl_strerror (status));
    
    gsl_multifit_fdfsolver_free (s);
    gsl_matrix_free (covar);
    gsl_rng_free (r);
    return [NSArray arrayWithObjects:[NSNumber numberWithDouble:Go],
            [NSNumber numberWithDouble:A], [NSNumber numberWithDouble:B],
            [NSNumber numberWithDouble:C], nil];
}


- (NSArray *)getCubicCoefficients:(NSArray *)values num:(int)n {
    //NSLog(@"In getCubicCoefficients");
    // quadratic fit
    double xi, yi, ei, chisq;
    gsl_matrix *X, *cov;
    gsl_vector *y2, *w, *c;
    int i;
    double nu = 3;
    
    //n = atoi (argv[1]);
    
    X = gsl_matrix_alloc (n, 2);
    y2 = gsl_vector_alloc (n);
    w = gsl_vector_alloc (n);
    
    c = gsl_vector_alloc (2);
    cov = gsl_matrix_alloc (2, 2);
    
    for (i = 0; i < n; i++)
    {
        xi=[[[values objectAtIndex:i] valueForKey:@"x"] doubleValue];
        yi=[[[values objectAtIndex:i] valueForKey:@"y"] doubleValue];
        ei=1;
        //printf ("%g %g +/- %g\n", xi, yi, ei);
        
        gsl_matrix_set (X, i, 0, 1.0);
        gsl_matrix_set (X, i, 1, pow(M_E, -xi/2.0)*pow(xi, ((nu/2)-1)));
        
        gsl_vector_set (y2, i, yi);
        gsl_vector_set (w, i, 1.0/(ei*ei));
    }
    
    gsl_multifit_linear_workspace * work = gsl_multifit_linear_alloc (n, 2);
    gsl_multifit_wlinear (X, w, y2, c, cov,
                          &chisq, work);
    gsl_multifit_linear_free (work);
    
#define C(i) (gsl_vector_get(c,(i)))
#define COV(i,j) (gsl_matrix_get(cov,(i),(j)))
    
    ////printf ("# best fit: Y = %g + %g sin(wt) + %g sin(2wt) + %g sin(3wt) + %g sin(4wt) + %g sin(5wt)\n", 
    //C(0), C(1), C(2), C(3), C(4), C(5));
    //printf ("# best fit: Y = %g + %g x + %g x^2 + %g x^3 + %g x^4 + %g x^5\n", 
    //C(0), C(1), C(2), C(3), C(4), C(5));

    //printf("# nu = %g, intercept = %g",C(1),C(0));
    //printf("# best fit: Y = %g + e^%g * x^%g ",C(1),pow(M_E, -C(0)/2),((C(0)/2)-1));
    
    return [NSArray arrayWithObjects:
            [NSNumber numberWithDouble:C(1)],
            [NSNumber numberWithDouble:C(0)], nil];
}

void
print_state (size_t iter, gsl_multifit_fdfsolver * s)
{
    //printf ("iter: %3zu x = % 15.8f % 15.8f % 15.8f "
            //"|f(x)| = %g\n",
            //iter,
            //gsl_vector_get (s->x, 0), 
            //gsl_vector_get (s->x, 1),
            //gsl_vector_get (s->x, 2), 
            //gsl_blas_dnrm2 (s->f));
}



@end
