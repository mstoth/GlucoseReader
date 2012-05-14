//
//  gmodel.h
//  GlucoseMonitor
//
//  Created by Michael Toth on 5/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef GlucoseMonitor_gmodel_h
#define GlucoseMonitor_gmodel_h
#include "gsl_matrix.h"
#include "gsl_vector.h"
#include "gsl_rng.h"

struct data {
    size_t n;
    double * x;
    double * y;
    double * sigma;
};

int gmodel_f (const gsl_vector * x, void *data, gsl_vector * f);
int gmodel_df (const gsl_vector * x, void *data, gsl_matrix * J);
int gmodel_fdf (const gsl_vector * x, void *data, gsl_vector * f, gsl_matrix * J);
gsl_rng *gsl_rng_alloc (const gsl_rng_type * T);

#endif
