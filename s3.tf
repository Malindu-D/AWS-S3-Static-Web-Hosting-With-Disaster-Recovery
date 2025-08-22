#S3 Main Bucket Configurations
resource "aws_s3_bucket" "s3-web-proj-bucket"{
    bucket = "s3-web-proj-bucket"
    
}

resource "aws_s3_bucket_ownership_controls" "ownershipMain" {
  bucket = aws_s3_bucket.s3-web-proj-bucket.bucket

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "publicMain" {
    bucket = aws_s3_bucket.s3-web-proj-bucket.bucket

    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
}

# resource "aws_s3_bucket_acl" "aclMain" {
#   depends_on = [ 
#     aws_s3_bucket_ownership_controls.ownershipMain,
#     aws_s3_bucket_public_access_block.publicMain
#    ]
#    bucket = aws_s3_bucket.s3-web-proj-bucket.bucket
#    acl = "public-read"
#}

resource "aws_s3_bucket_versioning" "versionMain" {
    bucket = aws_s3_bucket.s3-web-proj-bucket.bucket
    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_s3_bucket_website_configuration" "staticMain" {
  bucket = aws_s3_bucket.s3-web-proj-bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "policyMain" {
  bucket = aws_s3_bucket.s3-web-proj-bucket.bucket
  policy = data.aws_iam_policy_document.policyMainDoc.json
}

data "aws_iam_policy_document" "policyMainDoc" {
   statement {
    sid = "PublicRead"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.s3-web-proj-bucket.arn}/*",
    ]
  }
}

#S3 replication configuration
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "replication-role" {
  name               = "s3-web-proj-replication-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "replication" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]

    resources = [aws_s3_bucket.s3-web-proj-bucket.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]

    resources = ["${aws_s3_bucket.s3-web-proj-bucket.arn}/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]

    resources = ["${aws_s3_bucket.s3-web-proj-disaster-bucket.arn}/*"]
  }
}

resource "aws_iam_policy" "replication-policy" {
  name   = "s3-web-proj-replication-policy"
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication-role.name
  policy_arn = aws_iam_policy.replication-policy.arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.versionMain]

  role   = aws_iam_role.replication-role.arn
  bucket = aws_s3_bucket.s3-web-proj-bucket.id

  rule {
    id = "s3-web-proj-replication-rule"

    filter {
      prefix = ""
    }

    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.s3-web-proj-disaster-bucket.arn
      storage_class = "STANDARD"
    }
    delete_marker_replication {
      status = "Disabled"    #Disable because if main bucket loss index.html by accident it should not be replicate
    }
  }
}
##
#S3 Disaster Bucket Configurations
##

resource "aws_s3_bucket" "s3-web-proj-disaster-bucket"{
    provider = aws.disaster
    bucket = "s3-web-proj-disaster-bucket"
    
}

resource "aws_s3_bucket_ownership_controls" "ownershipDisaster" {
    provider = aws.disaster
    bucket = aws_s3_bucket.s3-web-proj-disaster-bucket.bucket

    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

resource "aws_s3_bucket_public_access_block" "publicDisaster" {
    provider = aws.disaster
    bucket = aws_s3_bucket.s3-web-proj-disaster-bucket.bucket

    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
}

# resource "aws_s3_bucket_acl" "aclDisaster" {
#     provider = aws.disaster
#     depends_on = [ 
#         aws_s3_bucket_ownership_controls.ownershipDisaster,
#         aws_s3_bucket_public_access_block.publicDisaster
#     ]
#     bucket = aws_s3_bucket.s3-web-proj-disaster-bucket.bucket
#     acl = "public-read"
# }

resource "aws_s3_bucket_versioning" "versionDisaster" {
    provider = aws.disaster
    bucket = aws_s3_bucket.s3-web-proj-disaster-bucket.bucket
    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_s3_bucket_website_configuration" "staticDisaster" {
    provider = aws.disaster
    bucket = aws_s3_bucket.s3-web-proj-disaster-bucket.bucket

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "error.html"
    }
}

resource "aws_s3_bucket_policy" "policyDisaster" {
    provider = aws.disaster
    bucket = aws_s3_bucket.s3-web-proj-disaster-bucket.bucket
    policy = data.aws_iam_policy_document.policyDisasterDoc.json
}

data "aws_iam_policy_document" "policyDisasterDoc" {
   statement {
    sid = "PublicRead"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.s3-web-proj-disaster-bucket.arn}/*",
    ]
  }
}
