resource "aws_codepipeline" "cicd_pipeline" {

    name = "tf-cicd"
    role_arn = aws_iam_role.tf-codepipeline-role.arn

    artifact_store {
        type="S3"
        location = aws_s3_bucket.code-pipeline.id
    }

    stage {
        name = "Source"
        action{
            name = "Source"
            category = "Source"
            owner = "AWS"
            provider = "CodeStarSourceConnection"
            version = "1"
            output_artifacts = ["tf-code"]
            configuration = {
                FullRepositoryId = "suresh30467/codepipeline"
                BranchName   = "main"
                ConnectionArn = var.code_credentials
                OutputArtifactFormat = "CODE_ZIP"
            }
        }
    }

    stage {
        name = "Deploy"
        action {
            name     = "Deploy"
            category = "Deploy"
            owner    = "AWS"
            provider = "S3"
            input_artifacts = ["tf-code"]
            version = "1"
        
        configuration = {
            BucketName = aws_s3_bucket.website.id
            Extract    = "true"
            }
        }
    }
}