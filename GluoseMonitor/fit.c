//
//  fit.c
//  GlucoseMonitor
//
//  Created by Michael Toth on 4/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <stdio.h>
#include "gsl_fit.h"

int
fit (int n, double x[], double y[], double w[], double *c0, double *c1)
{
    int i;
    
    double  cov00, cov01, cov11, chisq;
    
    gsl_fit_wlinear (x, 1, w, 1, y, 1, n, 
                     c0, c1, &cov00, &cov01, &cov11, 
                     &chisq);
    
    printf ("# best fit: Y = %g + %g X\n", *c0, *c1);
    printf ("# covariance matrix:\n");
    printf ("# [ %g, %g\n#   %g, %g]\n", 
            cov00, cov01, cov01, cov11);
    printf ("# chisq = %g\n", chisq);
    
    for (i = 0; i < n; i++)
        printf ("data: %g %g %g\n", 
                x[i], y[i], 1/sqrt(w[i]));
    
    printf ("\n");
    
    for (i = -30; i < 130; i++)
    {
        double xf = x[0] + (i/100.0) * (x[n-1] - x[0]);
        double yf, yf_err;
        
        gsl_fit_linear_est (xf, 
                            *c0, *c1, 
                            cov00, cov01, cov11, 
                            &yf, &yf_err);
        
        printf ("fit: %g %g\n", xf, yf);
        printf ("hi : %g %g\n", xf, yf + yf_err);
        printf ("lo : %g %g\n", xf, yf - yf_err);
    }
    return 0;
}