const METIS_NOPTIONS = 40
## Return codes 
const METIS_OK           = 1  # normal return
const METIS_ERROR_INPUT  = -2 # erroneous inputs and/or options
const METIS_ERROR_MEMORY = -3 # insufficient memory
const METIS_ERROR        = -4 # Other errors
## Operation type codes
const METIS_OP_PMETIS = 0
const METIS_OP_KMETIS = 1
const METIS_OP_OMETIS = 2
## (1-based) positions in options vector
const METIS_OPTION_PTYPE     = 1
const METIS_OPTION_OBJTYPE   = 2
const METIS_OPTION_CTYPE     = 3
const METIS_OPTION_IPTYPE    = 4
const METIS_OPTION_RTYPE     = 5
const METIS_OPTION_DBGLVL    = 6
const METIS_OPTION_NITER     = 7
const METIS_OPTION_NCUTS     = 8
const METIS_OPTION_SEED      = 9
const METIS_OPTION_NO2HOP    = 10
const METIS_OPTION_MINCONN   = 11
const METIS_OPTION_CONTIG    = 12
const METIS_OPTION_COMPRESS  = 13
const METIS_OPTION_CCORDER   = 14
const METIS_OPTION_PFACTOR   = 15
const METIS_OPTION_NSEPS     = 16
const METIS_OPTION_UFACTOR   = 17
const METIS_OPTION_NUMBERING = 18
const METIS_OPTION_HELP      = 19
const METIS_OPTION_TPWGTS    = 20
const METIS_OPTION_NCOMMON   = 21
const METIS_OPTION_NOOUTPUT  = 22
const METIS_OPTION_BALANCE   = 23
const METIS_OPTION_GTYPE     = 24
const METIS_OPTION_UBVEC     = 25
## Partitioning Schemes ## Warning that types need to be adapted
const METIS_PTYPE_RB   = 0
const METIS_PTYPE_KWAY = 1
## Graph types for meshes
const METIS_GTYPE_DUAL  = 0
const METIS_GTYPE_NODAL = 1
## Coarsening Schemes
const METIS_CTYPE_RM   = 0
const METIS_CTYPE_SHEM = 1
## Initial partitioning schemes
const METIS_IPTYPE_GROW    = 0
const METIS_IPTYPE_RANDOM  = 1
const METIS_IPTYPE_EDGE    = 2
const METIS_IPTYPE_NODE    = 3
const METIS_IPTYPE_METISRB = 4
## Refinement schemes
const METIS_RTYPE_FM        = 0
const METIS_RTYPE_GREEDY    = 1
const METIS_RTYPE_SEP2SIDED = 2
const METIS_RTYPE_SEP1SIDED = 3
## Debug levels (bit positions)
const METIS_DBG_INFO       = 1 # Shows various diagnostic messages
const METIS_DBG_TIME       = 2 # Perform timing analysis
const METIS_DBG_COARSEN    = 4 # Show the coarsening progress
const METIS_DBG_REFINE     = 8 # Show the refinement progress
const METIS_DBG_IPART      = 16 # Show info on initial partitioning
const METIS_DBG_MOVEINFO   = 32 # Show info on vertex moves during refinement
const METIS_DBG_SEPINFO    = 64 # Show info on vertex moves during sep refinement
const METIS_DBG_CONNINFO   = 128 # Show info on minimization of subdomain connectivity
const METIS_DBG_CONTIGINFO = 256 # Show info on elimination of connected components
const METIS_DBG_MEMORY     = 2048 # Show info related to wspace allocation
## Types of objectives
const METIS_OBJTYPE_CUT  = 0
const METIS_OBJTYPE_VOL  = 1
const METIS_OBJTYPE_NODE = 2
